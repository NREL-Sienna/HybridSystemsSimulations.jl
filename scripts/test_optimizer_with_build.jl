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
using HybridSystemsSimulations
const PSI = PowerSimulations
const PSB = PowerSystemCaseBuilder

include("utils.jl")

### Create Custom System
#sys = build_system(PSISystems, "modified_RTS_GMLC_RT_sys"; horizon = 864, force_build = true)
sys = PSB.build_RTS_GMLC_RT_sys(raw_data=PSB.RTS_DIR, horizon=864)

# Attach Data to System Ext
bus_name = "chuhsi"

sys.internal.ext = Dict{String, DataFrame}()
dic = get_ext(sys)
dic["b_df"] = CSV.read("inputs/$(bus_name)_battery_data.csv", DataFrame)
dic["th_df"] = CSV.read("inputs/$(bus_name)_thermal_data.csv", DataFrame)
dic["P_da"] = CSV.read("inputs/$(bus_name)_renewable_forecast_DA.csv", DataFrame)
dic["P_rt"] = CSV.read("inputs/$(bus_name)_renewable_forecast_RT.csv", DataFrame)
dic["λ_da_df"] = CSV.read("inputs/$(bus_name)_DA_AS_prices.csv", DataFrame)
dic["λ_rt_df"] = CSV.read("inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic["Pload_da"] = CSV.read("inputs/$(bus_name)_load_forecast_DA.csv", DataFrame)
dic["Pload_rt"] = CSV.read("inputs/$(bus_name)_load_forecast_RT.csv", DataFrame)

### Create Decision Problem
m = DecisionModel(
    MerchantHybridEnergyOnly,
    ProblemTemplate(CopperPlatePowerModel),
    sys,
    optimizer=Xpress.Optimizer,
    calculate_conflict=true,
    store_variable_names=true,
)
PSI.build!(m, output_dir=pwd())

PSI.solve!(m)
res = ProblemResults(m)
dic_res = get_variable_values(res)
#read_variables(res)
#dic[PSI.VariableKey{EnergyDABidIn, HybridSystem}("")]
#df = read_variable(res, PSI.VariableKey{energyRTBidIn, HybridSystem}(""))
energy_rt_out = read_variable(res, "energyRTBidOut__HybridSystem")[!, 2]
energy_rt_in = read_variable(res, "energyRTBidIn__HybridSystem")[!, 2]
p_out = read_variable(res, "ActivePowerOutVariable__HybridSystem")[!, 2]
p_in = read_variable(res, "ActivePowerInVariable__HybridSystem")[!, 2]
#df["ene"]
