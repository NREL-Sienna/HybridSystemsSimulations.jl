using Revise
using Pkg
Pkg.activate("test")
Pkg.instantiate()

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
using Dates

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

#sys_rts_da =  PSB.make_modified_RTS_GMLC_sys(Hour(1), raw_data=PSB.RTS_DIR, horizon=864)
#sys_rts_rt =  PSB.make_modified_RTS_GMLC_sys(Dates.Minute(5); raw_data=PSB.RTS_DIR)
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

template_uc_dcp = get_uc_dcp_template()
set_device_model!(
    template_uc_dcp,
    DeviceModel(
        PSY.HybridSystem,
        HybridEnergyOnlyDispatch;
        attributes=Dict{String, Any}("cycling" => true),
    ),
)

m = DecisionModel(
    template_uc_dcp,
    sys_rts_da,
    optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.1),
    calculate_conflict=true,
    store_variable_names=true,
    optimizer_solve_log_print=true,
)

PSI.build!(m, output_dir=pwd())

PSI.solve!(m)
res = ProblemResults(m)
dic_res = get_variable_values(res)

p_out = read_variable(res, "ActivePowerOutVariable__HybridSystem")[!, 2]
p_in = read_variable(res, "ActivePowerInVariable__HybridSystem")[!, 2]

using Plots
plot(p_out / 100.0)
plot!(-p_in / 100.0)

plot((p_out - p_in) / 100.0)
