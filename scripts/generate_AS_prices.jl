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
using Statistics

###############################
######## Load Scripts #########
###############################
include("get_templates.jl")
include("modify_systems.jl")
include("price_generation_utils.jl")
include("build_simulation_cases.jl")
include("utils.jl")

###############################
######## Load Systems #########
###############################

# DA system don't have Reserves
sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys")
sys_rts_rt = build_system(PSISystems, "modified_RTS_GMLC_RT_sys")

res_reg_up = get_component(VariableReserve, sys_rts_rt, "Reg_Up")
res_reg_down = get_component(VariableReserve, sys_rts_rt, "Reg_Down")
res_spin_up = get_component(VariableReserve, sys_rts_rt, "Spin_Up_R1")

reg_up_ta = get_time_series_array(
    SingleTimeSeries,
    res_reg_up,
    "requirement",
    start_time = DateTime("2020-10-03T00:00:00"),
    len = 24*3*12,
)

reg_down_ta = get_time_series_array(
    SingleTimeSeries,
    res_reg_down,
    "requirement",
    start_time = DateTime("2020-10-03T00:00:00"),
    len = 24*3*12,
)

reg_spin_ta = get_time_series_array(
    SingleTimeSeries,
    res_spin_up,
    "requirement",
    start_time = DateTime("2020-10-03T00:00:00"),
    len = 24*3*12,
)

hourly_range = 1:12:864
reg_up_DA = reg_up_ta[hourly_range]
reg_down_DA = reg_down_ta[hourly_range]
reg_spin_DA = reg_spin_ta[hourly_range]

prices_DA = CSV.read("inputs/chuhsi_DA_prices.csv", DataFrame)
λ_DA = prices_DA[!, "Chuhsi"]
λ_average = mean(λ_DA)
λ_average_reg = λ_average / 10.0
λ_average_spin = λ_average / 20.0

reg_up_prices = values(reg_up_DA) .* λ_average_reg
reg_down_prices = values(reg_down_DA) .* λ_average_reg
reg_spin_prices = values(reg_spin_DA) .* λ_average_spin

prices_DA[!, "Reg_Up_Prices"] = reg_up_prices
prices_DA[!, "Reg_Down_Prices"] = reg_down_prices
prices_DA[!, "Reg_Spin_Prices"] = reg_spin_prices
prices_DA

# Store results
CSV.write("inputs/chuhsi_DA_AS_prices.csv", prices_DA)