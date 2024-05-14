using Pkg
Pkg.activate("test")
Pkg.instantiate()

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
using JuMP
using Logging
using Dates
using CSV
using TimeSeries

@static if haskey(ENV, "NREL_CLUSTER")
    using Gurobi
    mipgap = 0.001
    optimizer = optimizer_with_attributes(
        Gurobi.Optimizer,
        "Threads" => (length(Sys.cpu_info()) ÷ 2) - 1,
        "MIPGap" => mipgap,
        "TimeLimit" => 3000,
    )
else
    using Xpress
    mipgap = 0.03
    optimizer = optimizer_with_attributes(
        Xpress.Optimizer,
        "MAXTIME" => 3000, # Stop after 50 Minutes
        "THREADS" => length(Sys.cpu_info()) ÷ 2,
        "MIPRELSTOP" => mipgap,
    )
end

if isempty(ARGS)
    push!(ARGS, "use_services")
    push!(ARGS, "2020-07-10T00:00:00")
    push!(ARGS, "2")
end

### Run read centralized results first ###
include("../get_templates.jl")
include("../modify_systems.jl")
include("../price_generation_utils.jl")
include("../build_simulation_cases_reserves.jl")
include("../utils.jl")

if isfile("modified_RTS_GMLC_DA_sys_noForecast.json")
    sys_rts_da = System("modified_RTS_GMLC_DA_sys_noForecast.json")
    sys_rts_merchant_da = System("modified_RTS_GMLC_RT_sys_noForecast.json")
else
    sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys_noForecast")
    sys_rts_merchant_da = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
    to_json(sys_rts_da, "modified_RTS_GMLC_DA_sys_noForecast.json")
end

if isfile("modified_RTS_GMLC_RT_sys_noForecast.json")
    #sys_rts_rt = System("modified_RTS_GMLC_RT_sys_noForecast.json")
    sys_rts_merchant_rt = System("modified_RTS_GMLC_RT_sys_noForecast.json")
else
    #sys_rts_rt = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
    sys_rts_merchant_rt = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
    to_json(sys_rts_merchant_rt, "modified_RTS_GMLC_RT_sys_noForecast.json")
end

#interval_DA = Hour(24)
#horizon_DA = 72
interval_DA = Hour(24)
horizon_DA = 72
transform_single_time_series!(sys_rts_da, horizon_DA, interval_DA)
#interval_RT = Minute(5)
#horizon_RT = 24
interval_RT = Hour(1)
horizon_RT = 12
#transform_single_time_series!(sys_rts_rt, horizon_RT, interval_RT)

###################################
###### Add Hybrid to System #######
###################################
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

if ARGS[1] == "use_services"
    results_prices = "HybridDispatchWithReserves"
    formulation = MerchantHybridCooptimizerCase
else
    results_prices = "HybridEnergyOnlyDispatch"
    formulation = MerchantHybridEnergyCase
end

starttime = DateTime(ARGS[2])
num_steps = parse(Int, ARGS[3])

results_folder = joinpath(
    "/Users/jlara/.julia/dev/HybridSystemsSimulations/centralized_sim_HybridDispatchWithReserves_2020-07-10T00:00:00",
)

results_dcp = SimulationResults(results_folder; ignore_status=true)

results_ed_dcp = get_decision_problem_results(results_dcp, "ED")
results_uc_dcp = get_decision_problem_results(results_dcp, "UC")

DA_prices = read_realized_dual(results_uc_dcp, "CopperPlateBalanceConstraint__System")
RT_prices = read_realized_dual(results_ed_dcp, "CopperPlateBalanceConstraint__System")
# Rescaling of prices from p.u.

DA_prices[!, 2] = DA_prices[!, 2] ./ 100.0
RT_prices[!, 2] = RT_prices[!, 2] ./ 100.0 * 60 / 5

DataFrames.rename!(DA_prices, [:DateTime, Symbol("$(bus_to_add)")])
DataFrames.rename!(RT_prices, [:DateTime, Symbol("$(bus_to_add)")])
###################################
####### Add Prices to EXT #########
###################################

dic = PSY.get_ext(sys_rts_merchant_da)

bus_name = "chuhsi"
dic["λ_da_df"] = DA_prices
dic["λ_rt_df"] = RT_prices

dic["λ_Reg_Up"] = DataFrame(
    "DateTime" => DA_prices[!, 1],
    "Chuhsi" => clamp.(DA_prices[!, 2] / 10.0, 0.0, 10000),
)
dic["λ_Reg_Down"] = DataFrame(
    "DateTime" => DA_prices[!, 1],
    "Chuhsi" => clamp.(DA_prices[!, 2] / 12.0, 0.0, 10000),
)
dic["λ_Spin_Up_R3"] = DataFrame(
    "DateTime" => DA_prices[!, 1],
    "Chuhsi" => clamp.(DA_prices[!, 2] / 25.0, 0.0, 10000),
)
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

served_fraction_map = Dict(
    "Spin_Up_R2" => 0.00,
    "Spin_Up_R3" => 0.00,
    "Reg_Up" => 0.3,
    "Spin_Up_R1" => 0.00,
    "Flex_Up" => 0.1,
    "Reg_Down" => 0.3,
    "Flex_Down" => 0.1,
)

for sys in [sys_rts_da, sys_rts_merchant_rt, sys_rts_merchant_da]
    services = get_components(VariableReserve, sys)
    hy_sys = first(get_components(HybridSystem, sys))
    for service in services
        serv_name = get_name(service)
        serv_frac = served_fraction_map[serv_name]
        set_deployed_fraction!(service, serv_frac)
        if contains(serv_name, "Spin_Up_R1") |
           contains(serv_name, "Spin_Up_R2") |
           contains(serv_name, "Flex")
            continue
        else
            if formulation == MerchantHybridCooptimizerCase
                add_service!(hy_sys, service, sys)
            end
        end
    end
end

###################################
######### Load Templates ##########
###################################

######################################################
####### Template for DA Bids ##########
######################################################

template_merchant_da = get_uc_copperplate_template(sys_rts_da)

set_device_model!(
    template_merchant_da,
    DeviceModel(
        PSY.HybridSystem,
        HybridDispatchWithReserves;
        #HybridEnergyOnlyDispatch;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "storage_reservation" => true,
            "energy_target" => true,
            "cycling" => true,
            "regularization" => true,
        ),
    ),
)

decision_optimizer_DA = DecisionModel(
    formulation,
    template_merchant_da,
    sys_rts_merchant_da,
    optimizer=optimizer_with_attributes(
        Xpress.Optimizer,
        "MAXTIME" => 3000, # Stop after 50 Minutes
        "THREADS" => length(Sys.cpu_info()) ÷ 2,
        "MIPRELSTOP" => mipgap,
    ),
    system_to_file=false,
    initialize_model=true,
    optimizer_solve_log_print=false,
    direct_mode_optimizer=true,
    rebuild_model=false,
    store_variable_names=true,
    calculate_conflict=true,
    name=name = "$(formulation)_DA",
)

######################################################
####### Template for DA Market Clearing ##########
######################################################
template_uc_copperplate = get_uc_copperplate_template(sys_rts_da)
set_device_model!(
    template_uc_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridFixedDA;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)

######################################################
####### Template for RT Bids ##########
######################################################
template_merchant_rt = get_uc_copperplate_template(sys_rts_da)

set_device_model!(
    template_merchant_rt,
    DeviceModel(
        PSY.HybridSystem,
        HybridDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "storage_reservation" => true,
            "energy_target" => true,
            "cycling" => false,
            "regularization" => true,
        ),
    ),
)

decision_optimizer_RT = DecisionModel(
    formulation,
    template_merchant_rt,
    sys_rts_merchant_rt,
    optimizer=optimizer_with_attributes(
        Xpress.Optimizer,
        "MAXTIME" => 3000, # Stop after 50 Minutes
        "THREADS" => length(Sys.cpu_info()) ÷ 2,
        "MIPRELSTOP" => mipgap,
    ),
    system_to_file=false,
    initialize_model=true,
    optimizer_solve_log_print=true,
    direct_mode_optimizer=true,
    rebuild_model=false,
    store_variable_names=true,
    calculate_conflict=true,
    name="$(formulation)_RT",
)

decision_optimizer_RT.ext = Dict{String, Any}("RT" => true)

######################################################
####### Template for RT Market Clearing ##########
######################################################

template_ed_copperplate = get_uc_copperplate_template(sys_rts_da)
set_device_model!(template_ed_copperplate, ThermalStandard, ThermalBasicDispatch)
set_device_model!(template_ed_copperplate, HydroDispatch, FixedOutput)
#set_device_model!(template_ed, HydroEnergyReservoir, FixedOutput)
for s in values(template_ed_copperplate.services)
    s.use_slacks = true
end

set_device_model!(
    template_ed_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridFixedDA;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)

models = SimulationModels(
    decision_models=[
        decision_optimizer_DA,
        DecisionModel(
            template_uc_copperplate,
            sys_rts_da;
            name="UC",
            optimizer=optimizer_with_attributes(
                Xpress.Optimizer,
                "MAXTIME" => 3000, # Stop after 50 Minutes
                "THREADS" => length(Sys.cpu_info()) ÷ 2,
                "MIPRELSTOP" => mipgap,
            ),
            system_to_file=false,
            initialize_model=true,
            optimizer_solve_log_print=false,
            direct_mode_optimizer=true,
            rebuild_model=false,
            store_variable_names=true,
            calculate_conflict=true,
        ),
        decision_optimizer_RT,
        DecisionModel(
            template_ed_copperplate,
            sys_rts_merchant_rt;
            name="ED",
            optimizer=optimizer_with_attributes(
                Xpress.Optimizer,
                "MAXTIME" => 3000, # Stop after 50 Minutes
                "THREADS" => length(Sys.cpu_info()) ÷ 2,
                "MIPRELSTOP" => mipgap,
            ),
            system_to_file=false,
            initialize_model=true,
            optimizer_solve_log_print=false,
            direct_mode_optimizer=true,
            rebuild_model=false,
            store_variable_names=true,
            calculate_conflict=true,
            #check_numerical_bounds=false,
        ),
    ],
)

# Set-up the sequence Optimizer-UC
sequence = SimulationSequence(
    models=models,
    feedforwards=Dict(
        "UC" => [
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyDABidOut,
                affected_values=[ActivePowerOutVariable],
            ),
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyDABidIn,
                affected_values=[ActivePowerInVariable],
            ),
        ],
        "$(formulation)_RT" => [
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyDABidOut,
                affected_values=[EnergyDABidOut],
            ),
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyDABidIn,
                affected_values=[EnergyDABidIn],
            ),
            CyclingChargeLimitFeedforward(
                component_type=PSY.HybridSystem,
                source=HSS.CyclingChargeUsage,
                affected_values=[HSS.CyclingChargeLimitParameter],
                penalty_cost=0.0,
            ),
            CyclingDischargeLimitFeedforward(
                component_type=PSY.HybridSystem,
                source=HSS.CyclingDischargeUsage,
                affected_values=[HSS.CyclingDischargeLimitParameter],
                penalty_cost=0.0,
            ),
        ],
        "ED" => [
            SemiContinuousFeedforward(
                component_type=ThermalStandard,
                source=OnVariable,
                affected_values=[ActivePowerVariable],
            ),
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyRTBidOut,
                affected_values=[ActivePowerOutVariable],
            ),
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyRTBidIn,
                affected_values=[ActivePowerInVariable],
            ),
            LowerBoundFeedforward(
                component_type=VariableReserve{ReserveUp},
                source=ActivePowerReserveVariable,
                affected_values=[ActivePowerReserveVariable],
                add_slacks=true,
            ),
            LowerBoundFeedforward(
                component_type=VariableReserve{ReserveDown},
                source=ActivePowerReserveVariable,
                affected_values=[ActivePowerReserveVariable],
                add_slacks=true,
            ),
        ],
    ),
    ini_cond_chronology=InterProblemChronology(),
)

sim = Simulation(
    name="merchant_sim_$(formulation)_$(starttime)",
    steps=num_steps,
    models=models,
    sequence=sequence,
    initial_time=starttime,
    simulation_folder=".",
)

build!(sim; console_level=Logging.Info, serialize=false)
execute_status = execute!(sim;)
