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

###############################
######## Load Systems #########
###############################

sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys_noForecast")
sys_rts_rt = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")

# There is no Wind + Thermal in a Single Bus.
# We will try to pick the Wind in 317 bus Chuhsi
# It does not have thermal and load, so we will pick the adjacent bus 318: Clark
bus_to_add = "Chuhsi" # "Barton"
add_da_forecast_in_5_mins_to_rt!(sys_rts_rt, sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_da)
add_hybrid_to_chuhsi_bus!(sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_rt)
add_hybrid_to_chuhsi_bus!(sys_rts_rt)

#interval_DA = Hour(24)
#horizon_DA = 72
interval_DA = Hour(24)
horizon_DA = 72
transform_single_time_series!(sys_rts_da, horizon_DA, interval_DA)
#interval_RT = Minute(5)
#horizon_RT = 24
interval_RT = Hour(1)
horizon_RT = 12 * 24
transform_single_time_series!(sys_rts_rt, horizon_RT, interval_RT)

#########################################
######## Add Services to Hybrid #########
#########################################

served_fraction_map = Dict(
    "Spin_Up_R2" => 0.00,
    "Spin_Up_R3" => 0.00,
    "Reg_Up" => 0.3,
    "Spin_Up_R1" => 0.00,
    "Flex_Up" => 0.1,
    "Reg_Down" => 0.3,
    "Flex_Down" => 0.1,
)

for sys in [sys_rts_da, sys_rts_rt]
    services = get_components(VariableReserve, sys)
    hy_sys = first(get_components(HybridSystem, sys))
    for service in services
        serv_name = get_name(service)
        serv_ext = get_ext(service)
        serv_ext["served_fraction"] = served_fraction_map[serv_name]
        if contains(serv_name, "Spin_Up_R1") |
           contains(serv_name, "Spin_Up_R2") |
           contains(serv_name, "Flex")
            continue
        else
            add_service!(hy_sys, service, sys)
        end
    end
end

###############################
###### Create Templates #######
###############################

# CopperPlate
template_uc_copperplate = get_uc_copperplate_template(sys_rts_da)
template_ed_copperplate = get_ed_copperplate_template(sys_rts_rt)

# PTDF Bounded
template_uc_ptdf = get_uc_ptdf_template(sys_rts_da)
template_ed_ptdf = get_ed_ptdf_template(sys_rts_rt)

# PTDF Unbounded
template_uc_unbounded_ptdf = get_uc_ptdf_unbounded_template(sys_rts_da)
template_ed_unbounded_ptdf = get_ed_ptdf_unbounded_template(sys_rts_rt)

# DCP
template_uc_dcp = get_uc_dcp_template()
template_ed_dcp = get_ed_dcp_template()

set_device_model!(
    template_uc_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridDispatchWithReserves;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)

set_device_model!(
    template_ed_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridDispatchWithReserves;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)

###############################
###### Simulation Params ######
###############################

mipgap = 0.005
num_steps = 7
starttime = DateTime("2020-10-02T00:00:00")

###############################
##### Run DCP Simulation ######
###############################

models = SimulationModels(
    decision_models=[
        DecisionModel(
            template_uc_copperplate,
            sys_rts_da;
            name="UC",
            optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => mipgap),
            system_to_file=false,
            initialize_model=true,
            optimizer_solve_log_print=false,
            direct_mode_optimizer=true,
            rebuild_model=false,
            store_variable_names=true,
            #check_numerical_bounds=false,
        ),
        DecisionModel(
            template_ed_copperplate,
            sys_rts_rt;
            name="ED",
            optimizer=optimizer_with_attributes(Xpress.Optimizer),
            system_to_file=false,
            initialize_model=true,
            optimizer_solve_log_print=false,
            check_numerical_bounds=false,
            rebuild_model=false,
            calculate_conflict=true,
            store_variable_names=true,
            #export_pwl_vars = true,
        ),
    ],
)

# Set-up the sequence UC-ED
sequence = SimulationSequence(
    models=models,
    feedforwards=Dict(
        "ED" => [
            SemiContinuousFeedforward(
                component_type=ThermalStandard,
                source=OnVariable,
                affected_values=[ActivePowerVariable],
            ),
            LowerBoundFeedforward(
                component_type=VariableReserve{ReserveUp},
                source=ActivePowerReserveVariable,
                affected_values=[ActivePowerReserveVariable],
            ),
            LowerBoundFeedforward(
                component_type=VariableReserve{ReserveDown},
                source=ActivePowerReserveVariable,
                affected_values=[ActivePowerReserveVariable],
            ),
        ],
    ),
    ini_cond_chronology=InterProblemChronology(),
)

sim_dcp = Simulation(
    name="compact_sim",
    steps=num_steps,
    models=models,
    sequence=sequence,
    initial_time=starttime,
    simulation_folder=mktempdir(cleanup=true),
)

build_dcp = build!(sim_dcp; console_level=Logging.Info, serialize=false)

execute_status = execute!(sim_dcp; enable_progress_bar=true);

results_dcp = SimulationResults(sim_dcp; ignore_status=true)
results_ed_dcp = get_decision_problem_results(results_dcp, "ED")
results_uc_dcp = get_decision_problem_results(results_dcp, "UC")

p_re_da = read_realized_variable(results_uc_dcp, "RenewablePower__HybridSystem")[!, 2]
p_re = read_realized_variable(results_ed_dcp, "RenewablePower__HybridSystem")[!, 2]
p_th = read_realized_variable(results_ed_dcp, "ThermalPower__HybridSystem")[!, 2]
p_ds = read_realized_variable(results_ed_dcp, "BatteryDischarge__HybridSystem")[!, 2]
p_ch = read_realized_variable(results_ed_dcp, "BatteryCharge__HybridSystem")[!, 2]
p_out_centr =
    read_realized_variable(results_ed_dcp, "ActivePowerOutVariable__HybridSystem")[!, 2] /
    100.0
p_in_centr =
    read_realized_variable(results_ed_dcp, "ActivePowerInVariable__HybridSystem")[!, 2] /
    100.0
p_out_centr_da =
    read_realized_variable(results_uc_dcp, "ActivePowerOutVariable__HybridSystem")[!, 2] /
    100.0
p_in_centr_da =
    read_realized_variable(results_uc_dcp, "ActivePowerInVariable__HybridSystem")[!, 2] /
    100.0
#p_load =
#    read_realized_parameter(results_ed_dcp, "ElectricLoadTimeSeries__HybridSystem")[!, 2]
#p_asset = read_realized_variable(results_uc_dcp, "ActivePowerVariable__HybridSystem")
plot(p_re)

dates_uc = read_realized_dual(results_uc_dcp, "CopperPlateBalanceConstraint__System")[!, 1]
dates_ed = read_realized_dual(results_ed_dcp, "CopperPlateBalanceConstraint__System")[!, 1]
prices_uc_dcp =
    read_realized_dual(results_uc_dcp, "CopperPlateBalanceConstraint__System")[!, 2] ./
    100.0
prices_ed_dcp =
    read_realized_dual(results_ed_dcp, "CopperPlateBalanceConstraint__System")[!, 2] ./
    100.0 * 60 / 5

T_da = 1:length(dates_uc)
T_rt = 1:length(dates_ed)
tmap = [div(k - 1, Int(length(T_rt) / length(T_da))) + 1 for k in T_rt]
dart = [prices_uc_dcp[tmap[t]] - prices_ed_dcp[t] for t in T_rt]

#for (ix, v) in enumerate(prices_ed_dcp)
#    if v > 90.0
#        prices_ed_dcp[ix] = 90.0
#    end
#end

plot([
    scatter(x=dates_uc, y=prices_uc_dcp, name="λ_DA", line_shape="hv"),
    scatter(x=dates_ed, y=prices_ed_dcp, name="λ_RT", line_shape="hv"),
])

DA_prices = DataFrame()
DA_prices[!, "DateTime"] = dates_uc
DA_prices[!, "Chuhsi"] = prices_uc_dcp

RT_prices = DataFrame()
RT_prices[!, "DateTime"] = dates_ed
RT_prices[!, "Chuhsi"] = prices_ed_dcp

# Prices
CSV.write("scripts/cooptimizer_pipeline/inputs/chuhsi_DA_prices.csv", DA_prices)
CSV.write("scripts/cooptimizer_pipeline/inputs/chuhsi_RT_prices.csv", RT_prices)

# AS Prices Temporary Hack
reg_up = abs.(DA_prices[!, 2] / 10.0)
reg_dn = abs.(DA_prices[!, 2] / 12.0)
reg_spin = abs.(DA_prices[!, 2] / 25.0)

dates = DA_prices[!, 1]
df_spin = DataFrame("DateTime" => dates, "Chuhsi" => reg_spin)
df_up = DataFrame("DateTime" => dates, "Chuhsi" => reg_up)
df_dn = DataFrame("DateTime" => dates, "Chuhsi" => reg_dn)

CSV.write("scripts/cooptimizer_pipeline/inputs/chuhsi_RegUp_prices.csv", df_up)
CSV.write("scripts/cooptimizer_pipeline/inputs/chuhsi_RegDown_prices.csv", df_dn)
CSV.write("scripts/cooptimizer_pipeline/inputs/chuhsi_Spin_prices.csv", df_spin)
