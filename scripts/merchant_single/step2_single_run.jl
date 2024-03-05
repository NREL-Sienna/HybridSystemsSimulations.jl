using Pkg
Pkg.activate("test")
Pkg.instantiate()

using Revise

# Load SIIP Packages

using PowerSimulations
using PowerSystems
using PowerSystemCaseBuilder
using InfrastructureSystems
using PowerNetworkMatrices
using HybridSystemsSimulations
using HydroPowerSimulations
using StorageSystemsSimulations
import OrderedCollections: OrderedDict
const PSY = PowerSystems
const PSI = PowerSimulations
const PSB = PowerSystemCaseBuilder
const HSS = HybridSystemsSimulations

# Load Optimization and Useful Packages
using Xpress
using JuMP
using Logging
using Dates
using CSV
using TimeSeries
using PlotlyJS

###############################
######## Load Scripts #########
###############################
include("../get_templates.jl")
include("../modify_systems.jl")
include("../price_generation_utils.jl")
include("../build_simulation_cases_reserves.jl")
include("../utils.jl")

###########################################
### Systems for DA and Merchant DA Bids ###
###########################################
sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys_noForecast")
sys_rts_merchant_da = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
sys_rts_merchant_rt = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")

interval_DA = Hour(24)
horizon_DA = 72
interval_RT = Hour(1)
horizon_RT = 12 * 24

# There is no Wind + Thermal in a Single Bus.
# We will try to pick the Wind in 317 bus Chuhsi
# It does not have thermal and load, so we will pick the adjacent bus 318: Clark
bus_to_add = "Chuhsi" # "Barton"
add_da_forecast_in_5_mins_to_rt!(sys_rts_merchant_da, sys_rts_da)
add_da_forecast_in_5_mins_to_rt!(sys_rts_merchant_rt, sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_da)
add_hybrid_to_chuhsi_bus!(sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_merchant_da)
modify_ren_curtailment_cost!(sys_rts_merchant_rt)
add_hybrid_to_chuhsi_bus!(sys_rts_merchant_da)
add_hybrid_to_chuhsi_bus!(sys_rts_merchant_rt)
transform_single_time_series!(sys_rts_da, horizon_DA, interval_DA)
transform_single_time_series!(sys_rts_merchant_da, horizon_DA * 12, interval_DA)
transform_single_time_series!(sys_rts_merchant_rt, horizon_RT, interval_RT)

#########################################
########## Add Prices to EXT ############
#########################################
dic = PSY.get_ext(sys_rts_merchant_da)
bus_name = "chuhsi"
dic["λ_da_df"] =
    CSV.read("scripts/cooptimizer_pipeline/inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] =
    CSV.read("scripts/cooptimizer_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic["λ_Reg_Up"] =
    CSV.read("scripts/cooptimizer_pipeline/inputs/$(bus_name)_RegUp_prices.csv", DataFrame)
dic["λ_Reg_Down"] = CSV.read(
    "scripts/cooptimizer_pipeline/inputs/$(bus_name)_RegDown_prices.csv",
    DataFrame,
)
dic["λ_Spin_Up_R3"] =
    CSV.read("scripts/cooptimizer_pipeline/inputs/$(bus_name)_Spin_prices.csv", DataFrame)
dic["horizon_RT"] = horizon_RT
dic["horizon_DA"] = horizon_DA

sys_rts_merchant_da.internal.ext = deepcopy(dic)
sys_rts_merchant_da.internal.ext["horizon_RT"] = horizon_DA * 12
hy_sys_da = first(get_components(HybridSystem, sys_rts_merchant_da))
PSY.set_ext!(hy_sys_da, sys_rts_merchant_da.internal.ext)
sys_rts_merchant_rt.internal.ext = deepcopy(dic)
sys_rts_merchant_rt.internal.ext["horizon_DA"] = horizon_RT ÷ 12
hy_sys_rt = first(get_components(HybridSystem, sys_rts_merchant_rt))
PSY.set_ext!(hy_sys_rt, sys_rts_merchant_rt.internal.ext)

template_uc_copperplate = get_uc_copperplate_template(sys_rts_da)

decision_optimizer_DA = DecisionModel(
    MerchantHybridCooptimizerCase,
    template_uc_copperplate,
    sys_rts_merchant_da,
    optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.01),
    calculate_conflict=true,
    optimizer_solve_log_print=false,
    system_to_file=false,
    store_variable_names=true;
    name="MerchantHybridCooptimizer_DA",
)

# Construct decision models for simulation
models = SimulationModels(
    decision_models=[
        decision_optimizer_DA,
    ],
)

# Set-up the sequence Optimizer-UC
sequence = SimulationSequence(
    models=models,
    ini_cond_chronology=InterProblemChronology(),
)

sim = Simulation(
    name="compact_sim",
    steps=3,
    models=models,
    sequence=sequence,
    initial_time = DateTime("2020-10-02T00:00:00"),
    simulation_folder=mktempdir(cleanup=true),
)

build!(sim)

execute!(sim; enable_progress_bar=true)

results = SimulationResults(sim)
result_opt = get_decision_problem_results(results, "MerchantHybridCooptimizer_DA")

da_bid_out = read_variable(result_opt, "EnergyDABidOut__HybridSystem")
da_bid_in = read_variable(result_opt, "EnergyDABidIn__HybridSystem")

full_horizon = 72
da_bid_out_realized = zeros(full_horizon)
da_horizon = 24
i = 0
for (k, bid) in da_bid_out
    da_bid_out_realized[(da_horizon * i + 1):((i + 1) * da_horizon)] = bid[!,1][1:da_horizon]
    i = i + 1
end

da_bid_in_realized = zeros(full_horizon)
i = 0
for (k, bid) in da_bid_in
    da_bid_in_realized[(da_horizon * i + 1):((i + 1) * da_horizon)] = bid[!,1][1:da_horizon]
    i = i + 1
end

vars =[
"ActivePowerOutVariable__HybridSystem"
 "EnergyVariable__HybridSystem"
 #"BidReserveVariableIn__VariableReserve__ReserveUp__Spin_Up_R3"
 "EnergyBatteryDischargeBid__HybridSystem"
 #"BidReserveVariableIn__VariableReserve__ReserveUp__Reg_Up"
 "DischargingReserveVariable__VariableReserve__ReserveDown__Reg_Down"
 "ChargingReserveVariable__VariableReserve__ReserveUp__Reg_Up"
 "RenewableReserveVariable__VariableReserve__ReserveUp__Reg_Up"
 #"BidReserveVariableOut__VariableReserve__ReserveDown__Reg_Down"
 "BatteryDischarge__HybridSystem"
 #"BidReserveVariableIn__VariableReserve__ReserveDown__Reg_Down"
 "ChargingReserveVariable__VariableReserve__ReserveUp__Spin_Up_R3"
 "DischargingReserveVariable__VariableReserve__ReserveUp__Reg_Up"
 "RenewablePower__HybridSystem"
 "RenewableReserveVariable__VariableReserve__ReserveDown__Reg_Down"
 "ActivePowerInVariable__HybridSystem"
 "EnergyRTBidOut__HybridSystem"
 "BatteryStatus__HybridSystem"
 #"BidReserveVariableOut__VariableReserve__ReserveUp__Reg_Up"
 "RenewableReserveVariable__VariableReserve__ReserveUp__Spin_Up_R3"
 "EnergyBatteryChargeBid__HybridSystem"
 "BatteryCharge__HybridSystem"
 "ThermalPower__HybridSystem"
 "ThermalReserveVariable__VariableReserve__ReserveUp__Reg_Up"
 "DischargingReserveVariable__VariableReserve__ReserveUp__Spin_Up_R3"
 #"OnVariable__HybridSystem"
 "ThermalReserveVariable__VariableReserve__ReserveUp__Spin_Up_R3"
 "ReservationVariable__HybridSystem"
 #"BidReserveVariableOut__VariableReserve__ReserveUp__Spin_Up_R3"
 "ThermalReserveVariable__VariableReserve__ReserveDown__Reg_Down"
 "EnergyThermalBid__HybridSystem"
 "EnergyRenewableBid__HybridSystem"
 "ChargingReserveVariable__VariableReserve__ReserveDown__Reg_Down"
 "EnergyRTBidIn__HybridSystem"
]

rt_vars = read_realized_variables(result_opt, vars)
da_time_stamps = range(DateTime("2020-10-02T00:00:00"), length=72, step = Hour(1))
traces =[
    scatter(x=da_time_stamps, y=da_bid_out_realized, name="DA Bid Out", line_shape="hv"),
    scatter(x=da_time_stamps, y=-da_bid_in_realized, name="DA Bid In", line_shape="hv"),
]
for (k, v) in rt_vars
    push!(traces, scatter(x = v[!,:DateTime], y = v[!,2], name = k))
end

da = read_parameter(result_opt, "DayAheadEnergyPrice__HybridSystem__EnergyDABidIn")
da_price = zeros(full_horizon)
i = 0
for (k, bid) in da
    da_price[(da_horizon * i + 1):((i + 1) * da_horizon)] = -1*bid[!,1][1:24]
    i = i + 1
end

rt = read_realized_parameter(result_opt, "RealTimeEnergyPrice__HybridSystem__EnergyDABidOut")

DART = [da_price[tmap[t]] - rt[t,2] for t in 1:864]

push!(traces, scatter(x=da_time_stamps, y=da_bid_out_realized, name="DA Price", line_shape="hv"),)

PlotlyJS.plot(traces)
