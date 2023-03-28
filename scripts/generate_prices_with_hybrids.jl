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

for sys in [sys_rts_da, sys_rts_rt]
    bus_to_add = "Chuhsi" # "Barton"
    modify_ren_curtailment_cost!(sys)
    add_hybrid_to_chuhsi_bus!(sys)
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

execute_status = execute!(sim_dcp; enable_progress_bar=true);

results_dcp = SimulationResults(sim_dcp; ignore_status=true)
results_ed_dcp = get_decision_problem_results(results_dcp, "ED")
results_uc_dcp = get_decision_problem_results(results_dcp, "UC")
prices_ed_dcp = get_psi_dcp_lmps(results_ed_dcp)
prices_uc_dcp = get_psi_dcp_lmps(results_uc_dcp)
dates_ed = prices_ed_dcp[!, "DateTime"]
dates_uc = prices_uc_dcp[!, "DateTime"]

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

p_ds_uc = read_realized_variable(results_uc_dcp, "BatteryDischarge__HybridSystem")[!, 2]
p_ch_uc = read_realized_variable(results_uc_dcp, "BatteryCharge__HybridSystem")[!, 2]
p_ds_ed = read_realized_variable(results_ed_dcp, "BatteryDischarge__HybridSystem")[!, 2]
p_ch_ed = read_realized_variable(results_ed_dcp, "BatteryCharge__HybridSystem")[!, 2]
p_out = read_realized_variable(results_uc_dcp, "ActivePowerOutVariable__HybridSystem")[!, 2]
soc_uc = read_realized_variable(results_uc_dcp, "EnergyVariable__HybridSystem")[!, 2]
soc_ed = read_realized_variable(results_ed_dcp, "EnergyVariable__HybridSystem")[!, 2]

using PlotlyJS
PlotlyJS.plot([
    PlotlyJS.scatter(x=dates_uc, y = DA_prices[!, bus_name], name = "λ_DA", line_shape = "hv"),
    PlotlyJS.scatter(x=dates_ed, y = RT_prices[!, bus_name], name = "λ_RT", line_shape = "hv"),
])

plot([
    scatter(x=dates_uc, y = p_ds_uc, name = "p_ds", line_shape = "hv"),
    scatter(x=dates_uc, y = -p_ch_uc, name = "p_ch", line_shape = "hv"),
    scatter(x=dates_uc, y = soc_uc, name = "soc", line_shape = "hv"),]
    )


plot([
        scatter(x=dates_ed, y = p_ds_ed, name = "p_ds", line_shape = "hv"),
        scatter(x=dates_ed, y = -p_ch_ed, name = "p_ch", line_shape = "hv"),
        scatter(x=dates_ed, y = soc_ed ./ 100.0, name = "soc", line_shape = "hv"),]
        )