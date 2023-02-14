using CSV
using DataFrames
using JuMP

b_df = CSV.read("scripts/results/barton_battery_data.csv", DataFrame)
th_df = CSV.read("scripts/results/barton_thermal_data.csv", DataFrame)
P_da = CSV.read("scripts/results/barton_renewable_forecast_DA.csv", DataFrame)
P_rt = CSV.read("scripts/results/barton_renewable_forecast_RT.csv", DataFrame)
λ_da = CSV.read("scripts/results/barton_RT_prices.csv", DataFrame)
λ_rt = CSV.read("scripts/results/barton_DA_prices.csv", DataFrame)