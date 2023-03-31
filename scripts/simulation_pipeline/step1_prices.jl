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

sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys")
sys_rts_rt = build_system(PSISystems, "modified_RTS_GMLC_RT_sys")

# There is no Wind + Thermal in a Single Bus.
# We will try to pick the Wind in 317 bus Chuhsi
# It does not have thermal and load, so we will pick the adjacent bus 318: Clark

for sys in [sys_rts_da, sys_rts_rt]
    bus_to_add = "Chuhsi" # "Barton"
    modify_ren_curtailment_cost!(sys)
    add_hybrid_to_chuhsi_bus!(sys)
    #for l in get_components(PowerLoad, sys)
    #    set_max_active_power!(l, get_max_active_power(l) * 1.3)
    #end
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

mipgap = 0.005
num_steps = 3
starttime = DateTime("2020-10-03T00:00:00")

###############################
##### Run DCP Simulation ######
###############################

sim_dcp = build_simulation_case(
    template_uc_copperplate,
    template_ed_copperplate,
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
p_load =
    read_realized_parameter(results_ed_dcp, "ElectricLoadTimeSeries__HybridSystem")[!, 2]
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
CSV.write("scripts/simulation_pipeline/inputs/chuhsi_DA_prices.csv", DA_prices)
CSV.write("scripts/simulation_pipeline/inputs/chuhsi_RT_prices.csv", RT_prices)
