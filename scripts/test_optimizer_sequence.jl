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
include("build_simulation_cases.jl")
include("utils.jl")
include("../src/formulations.jl")
include("../src/variables_constraints.jl")
include("../src/hybrid_build.jl")

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

mipgap = 0.01
num_steps = 3
starttime = DateTime("2020-10-03T00:00:00")

### Create Custom System
sys = build_system(PSISystems, "modified_RTS_GMLC_DA_sys")

# Attach Data to System Ext
bus_name = "chuhsi"

sys.internal.ext = Dict{String, DataFrame}()
dic = get_ext(sys)
dic["b_df"] = CSV.read("scripts/results_old/$(bus_name)_battery_data.csv", DataFrame)
dic["th_df"] = CSV.read("scripts/results_old/$(bus_name)_thermal_data.csv", DataFrame)
dic["P_da"] =
    CSV.read("scripts/results_old/$(bus_name)_renewable_forecast_DA.csv", DataFrame)
dic["P_rt"] =
    CSV.read("scripts/results_old/$(bus_name)_renewable_forecast_RT.csv", DataFrame)
dic["λ_da_df"] = CSV.read("scripts/results_old/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] = CSV.read("scripts/results_old/$(bus_name)_RT_prices.csv", DataFrame)
dic["Pload_da"] =
    CSV.read("scripts/results_old/$(bus_name)_load_forecast_DA.csv", DataFrame)
dic["Pload_rt"] =
    CSV.read("scripts/results_old/$(bus_name)_load_forecast_RT.csv", DataFrame)

### Create Decision Problem
m = DecisionModel(
    HybridOptimizer,
    ProblemTemplate(CopperPlatePowerModel),
    sys,
    optimizer=Xpress.Optimizer,
    horizon=864,
)

sim_optimizer = build_simulation_case_optimizer(
    template_uc_dcp,
    m,
    sys_rts_da,
    sys_rts_rt,
    num_steps,
    0.01,
    starttime,
)

build!(sim_optimizer)

execute_status = execute!(sim_optimizer; enable_progress_bar=true);
