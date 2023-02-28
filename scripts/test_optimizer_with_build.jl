using Pkg
Pkg.activate("test")
Pkg.instantiate()

using Revise

using PowerSimulations
using PowerSystems
using PowerSystemCaseBuilder
using JuMP
using Xpress
using Logging
using Dates
using CSV
using TimeSeries
using DataFrames
const PSI = PowerSimulations

include("utils.jl")
include("../src/formulations.jl")
include("../src/variables_definitions.jl")
include("../src/constraints_definitions.jl")
include("../src/hybrid_build.jl")

### Create Custom System
sys = build_system(PSISystems, "modified_RTS_GMLC_RT_sys")

# Attach Data to System Ext
bus_name = "chuhsi"

sys.internal.ext = Dict{String, DataFrame}()
dic = get_ext(sys)
dic["b_df"] = CSV.read("inputs/$(bus_name)_battery_data.csv", DataFrame)
dic["th_df"] = CSV.read("inputs/$(bus_name)_thermal_data.csv", DataFrame)
dic["P_da"] = CSV.read("inputs/$(bus_name)_renewable_forecast_DA.csv", DataFrame)
dic["P_rt"] = CSV.read("inputs/$(bus_name)_renewable_forecast_RT.csv", DataFrame)
dic["λ_da_df"] = CSV.read("inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] = CSV.read("inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic["Pload_da"] = CSV.read("inputs/$(bus_name)_load_forecast_DA.csv", DataFrame)
dic["Pload_rt"] = CSV.read("inputs/$(bus_name)_load_forecast_RT.csv", DataFrame)

### Create Decision Problem
m = DecisionModel(
    HybridOptimizer,
    ProblemTemplate(CopperPlatePowerModel),
    sys,
    optimizer=Xpress.Optimizer,
)
PSI.build!(m, output_dir=pwd())

PSI.solve!(m)
container = PSI.get_optimization_container(m)
res = ProblemResults(m)
