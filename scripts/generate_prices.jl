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
import OrderedCollections: OrderedDict
const PSY = PowerSystems
const PSI = PowerSimulations
const PSB = PowerSystemCaseBuilder

# Load Optimization and Useful Packages
using Xpress
using JuMP
using Logging
using Dates
using CSV
using TimeSeries

###############################
######## Load Scripts #########
###############################
include("get_templates.jl")
include("modify_systems.jl")
include("price_generation_utils.jl")
include("build_simulation_cases_reserves.jl")
include("utils.jl")

###############################
######## Load Systems #########
###############################

sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys")
sys_rts_rt = build_system(PSISystems, "modified_RTS_GMLC_RT_sys")

# There is no Wind + Thermal in a Single Bus.
# We will try to pick the Wind in 317 bus Chuhsi
# It does not have thermal and load, so we will pick the adjacent bus 318: Clark

systems = [sys_rts_da, sys_rts_rt]
for sys in systems
    bus_to_add = "Chuhsi" # "Barton"
    modify_ren_curtailment_cost!(sys)
    add_battery_to_bus!(sys, bus_to_add)
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

###############################
###### Simulation Params ######
###############################

mipgap = 0.002
num_steps = 3
starttime = DateTime("2020-10-03T00:00:00")

#=

###############################
##### Run PTDF Bounded Sim ####
###############################

sim_ptdf = build_simulation_case(
    template_uc_ptdf,
    template_ed_ptdf,
    sys_rts_da,
    sys_rts_rt,
    num_steps,
    mipgap,
    starttime,
)
build_out = build!(sim_ptdf; console_level=Logging.Info, serialize=false)

execute_status = execute!(sim_ptdf; enable_progress_bar=true);

results_ptdf = SimulationResults(sim_ptdf; ignore_status=true)
results_ed_ptdf = get_decision_problem_results(results_ptdf, "ED")
results_uc_ptdf = get_decision_problem_results(results_ptdf, "UC")
ptdf = PTDF(sys_rts_rt)
prices_ptdf = get_psi_ptdf_lmps(results_uc_ptdf, ptdf)
cp_price_ptdf = get_copperplate_prices(results_uc_ptdf)

###############################
#### Run PTDF Unbounded Sim ###
###############################

sim_ptdf_unbounded = build_simulation_case(
    template_uc_unbounded_ptdf,
    template_ed_unbounded_ptdf,
    sys_rts_da,
    sys_rts_rt,
    num_steps,
    mipgap,
    starttime,
)
build_out = build!(sim_ptdf_unbounded; console_level=Logging.Info, serialize=false)

execute_status = execute!(sim_ptdf_unbounded; enable_progress_bar=true);

results_ptdf_unbounded = SimulationResults(sim_ptdf_unbounded; ignore_status=true)
results_ed_ptdf_unbounded = get_decision_problem_results(results_ptdf_unbounded, "ED")
results_uc_ptdf_unbounded = get_decision_problem_results(results_ptdf_unbounded, "UC")
cp_price_ptdf_unbounded = get_copperplate_prices(results_uc_ptdf_unbounded)

###############################
#### Run Copperplate Sim ######
###############################

sim_copperplate = build_simulation_case(
    template_uc_copperplate,
    template_ed_copperplate,
    sys_rts_da,
    sys_rts_rt,
    num_steps,
    mipgap,
    starttime,
)
build_out = build!(sim_copperplate; console_level=Logging.Info, serialize=false)

execute_status = execute!(sim_copperplate; enable_progress_bar=true);

results_copperplate = SimulationResults(sim_ptdf_unbounded; ignore_status=true)
results_ed_copperplate = get_decision_problem_results(results_copperplate, "ED")
results_uc_copperplate = get_decision_problem_results(results_copperplate, "UC")

prices_copperplate = get_copperplate_prices(results_uc_copperplate)

=#

###############################
##### Run DCP Simulation ######
###############################

sim_dcp = build_simulation_case(
    template_uc_dcp,
    template_ed_dcp,
    sys_rts_da,
    sys_rts_rt,
    num_steps,
    mipgap,
    starttime,
)
build_dcp = build!(sim_dcp; console_level=Logging.Info, serialize=false)

execute_status = execute!(sim_dcp; enable_progress_bar=false);

results_dcp = SimulationResults(sim_dcp; ignore_status=true)
results_ed_dcp = get_decision_problem_results(results_dcp, "ED")
results_uc_dcp = get_decision_problem_results(results_dcp, "UC")
prices_ed_dcp = get_psi_dcp_lmps(results_ed_dcp)
prices_uc_dcp = get_psi_dcp_lmps(results_uc_dcp)

###############################
## Get Normalized Bus Prices ##
###############################

UC_length = 1.0
ED_length = 1 / 12
base_power = 100.0
dcp_multiplier = -1.0 # -1.0 for DCP, 1.0 for PTDF
bus_name = "Chuhsi" #"Barton"

# Prices being zero are when the Battery is the Marginal Unit. These zero prices go away when the battery is removed from the system.
# Prices being -15.0 $/MWh are when Renewable is being curtailed
DA_prices = get_normalized_bus_prices(
    prices_uc_dcp,
    bus_name,
    UC_length,
    base_power,
    dcp_multiplier,
)
RT_prices = get_normalized_bus_prices(
    prices_ed_dcp,
    bus_name,
    ED_length,
    base_power,
    dcp_multiplier,
)

using Plots
plot(DA_prices[!, bus_name])
#show(barton_RT_prices, allrows=true)

###############################
##### Get Hybrid Sys Data #####
###############################
#=
thermal_name = "215_CT_4"
renewable_name = "215_PV_1"
battery_name = "215_BATTERY"
load_name = "Barton"
=#

thermal_name = "318_CC_1"
renewable_name = "317_WIND_1"
battery_name = "317_BATTERY"
load_name = "Clark"

r_gen_da = get_component(StaticInjection, sys_rts_da, renewable_name)
r_gen_rt = get_component(StaticInjection, sys_rts_rt, renewable_name)
t_gen = get_component(StaticInjection, sys_rts_da, thermal_name)
b_gen = get_component(StaticInjection, sys_rts_da, battery_name)
load_da = get_component(PowerLoad, sys_rts_da, load_name)
load_rt = get_component(PowerLoad, sys_rts_rt, load_name)

# Forecasts
maxpower_da_df = get_da_max_active_power_series(r_gen_da, starttime, num_steps)

maxpower_rt_df = get_rt_max_active_power_series(r_gen_rt, starttime, num_steps)

# Additional Data
bat_param_df = get_battery_params(b_gen)
thermal_param_df = get_thermal_params(t_gen)
load_da_df = get_da_max_active_power_series(load_da, starttime, num_steps)
load_rt_df = get_rt_max_active_power_series(load_rt, starttime, num_steps)

###############################
####### Export Results ########
###############################

# Prices
CSV.write("scripts/results/chuhsi_DA_prices.csv", DA_prices)
CSV.write("scripts/results/chuhsi_RT_prices.csv", RT_prices)

# Forecast
CSV.write("scripts/results/chuhsi_renewable_forecast_DA.csv", maxpower_da_df)
CSV.write("scripts/results/chuhsi_renewable_forecast_RT.csv", maxpower_rt_df)

# Load TimeSeries Forecast
CSV.write("scripts/results/chuhsi_load_forecast_DA.csv", load_da_df)
CSV.write("scripts/results/chuhsi_load_forecast_RT.csv", load_rt_df)

# Additional Data
CSV.write("scripts/results/chuhsi_battery_data.csv", bat_param_df)
CSV.write("scripts/results/chuhsi_thermal_data.csv", thermal_param_df)
