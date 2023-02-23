using CSV
using DataFrames
using PowerSystems
using JuMP
using Xpress

include("utils.jl")

###############################
####### Read DataFrames #######
###############################

bus_name = "chuhsi"

b_df = CSV.read("scripts/results_old/$(bus_name)_battery_data.csv", DataFrame)
th_df = CSV.read("scripts/results_old/$(bus_name)_thermal_data.csv", DataFrame)
P_da = CSV.read("scripts/results_old/$(bus_name)_renewable_forecast_DA.csv", DataFrame)
P_rt = CSV.read("scripts/results_old/$(bus_name)_renewable_forecast_RT.csv", DataFrame)
λ_da_df = CSV.read("scripts/results_old/$(bus_name)_DA_prices.csv", DataFrame)
λ_rt_df = CSV.read("scripts/results_old/$(bus_name)_RT_prices.csv", DataFrame)
Pload_da = CSV.read("scripts/results_old/$(bus_name)_load_forecast_DA.csv", DataFrame)
Pload_rt = CSV.read("scripts/results_old/$(bus_name)_load_forecast_RT.csv", DataFrame)

###############################
######## Create Sets ##########
###############################

dates_da = λ_da_df[!, "DateTime"]
dates_rt = λ_rt_df[!, "DateTime"]

T_da = 1:length(dates_da)
T_rt = 1:length(dates_rt)
tmap = [div(k - 1, Int(length(T_rt) / length(T_da))) + 1 for k in T_rt]
T_end = T_rt[end]

###############################
######## Parameters ###########
###############################

Bus_name = "Chuhsi"

# Hard Code for now
P_max_pcc = 10.0 # Infinity
VOM = 500.0
Δt_DA = 1.0
Δt_RT = 5 / 60
Cycles = 4.11;

# Thermal Params
P_max_th = get_row_val(th_df, "P_max")
P_min_th = get_row_val(th_df, "P_min")
C_th_var = get_row_val(th_df, "C_var") * 100.0 # Multiply by 100 to transform to $/pu
C_th_fix = get_row_val(th_df, "C_fix")

# Battery Params
P_ch_max = get_row_val(b_df, "P_ch_max")
P_ds_max = get_row_val(b_df, "P_ds_max")
η_ch = get_row_val(b_df, "η_in")
η_ds = get_row_val(b_df, "η_out")
inv_η_ds = 1.0 / η_ds
E_max = get_row_val(b_df, "SoC_max")
E_min = get_row_val(b_df, "SoC_min")
E0 = get_row_val(b_df, "initial_energy")

# Renewable Forecast
P_re_star = P_rt[!, "MaxPower"]

# Load Forecast
P_ld = Pload_rt[!, "MaxPower"] * 0.0

# Forecast Prices
λ_da = λ_da_df[!, Bus_name] * 100.0 # Multiply by 100 to transform to $/pu
λ_rt = λ_rt_df[!, Bus_name] * 100.0 # Multiply by 100 to transform to $/pu

###############################
######### Variables ###########
###############################

m = Model(Xpress.Optimizer)

### Market Variables ###
# DA energy bids
@variable(m, 0.0 <= eb_da_out[T_da] <= P_max_pcc)
@variable(m, 0.0 <= eb_da_in[T_da] <= P_max_pcc)
# RT energy bids
@variable(m, 0.0 <= eb_rt_out[T_rt] <= P_max_pcc)
@variable(m, 0.0 <= eb_rt_in[T_rt] <= P_max_pcc)

### Physical Variables ###
# PCC Vars
@variable(m, 0.0 <= p_out[T_rt] <= P_max_pcc)
@variable(m, 0.0 <= p_in[T_rt] <= P_max_pcc)
@variable(m, status[T_rt], Bin)
# Thermal Vars
@variable(m, 0.0 <= p_th[T_rt] <= P_max_th)
@variable(m, on_th[T_da], Bin) # On for thermal is used as 1 hour DA decision
fix.(on_th, 0, force=true)
# Renewable Variables
@variable(m, 0.0 <= p_re[i=1:length(dates_rt)] <= P_re_star[i])
# Battery Variables
@variable(m, 0.0 <= p_ch[T_rt] <= P_ch_max)
@variable(m, 0.0 <= p_ds[T_rt] <= P_ds_max)
@variable(m, status_st[T_rt], Bin)
@variable(m, E_min <= e_st[T_rt] <= E_max)

###############################
####### Obj. Function #########
###############################

@objective(
    m,
    Max,
    Δt_DA * sum(λ_da .* (eb_da_out - eb_da_in)) - Δt_DA * sum(C_th_fix * on_th) +
    Δt_RT *
    (sum(λ_rt .* (eb_rt_out - eb_rt_in)) - sum(C_th_var * p_th + VOM * (p_ch + p_ds)))
)

###############################
######## Constraints ##########
###############################

# Market Constraints
# bids being less than PCC is being bounded by the limits in the variable definition
# bids in/out
@constraint(m, eb_rt_out .== p_out)
@constraint(m, eb_rt_in .== p_in)

# Status Battery
@constraint(m, (1.0 .- status) * P_max_pcc .>= p_in)
@constraint(m, status * P_max_pcc .>= p_out)

# Power Balance
@constraint(m, p_th + p_re + p_ds - p_ch - P_ld - p_out + p_in .== 0.0)

# Thermal Constraints
for t in T_rt
    @constraint(m, p_th[t] <= on_th[tmap[t]] * P_max_th)
    @constraint(m, p_th[t] >= on_th[tmap[t]] * P_min_th)
end

# Battery Power Constraints
@constraint(m, p_ch .<= (1.0 .- status_st) .* P_ch_max)
@constraint(m, p_ds .<= status_st .* P_ds_max)

# Battery Energy Constraints
# Initial Time
@constraint(m, E0 + Δt_RT * (p_ch[1] * η_ch - p_ds[1] * inv_η_ds) == e_st[1])
# Mid Times
for t in 2:T_end
    @constraint(m, e_st[t - 1] + Δt_RT * (p_ch[t] * η_ch - p_ds[t] * inv_η_ds) == e_st[t])
end
# Final Time: Feasible SoC at the end
#@constraint(m, e_st[T_end] + p_ch[T_end] * η_ch - p_ds[T_end] * inv_η_ds >= E_min)

# Cycling Constraints
@constraint(m, inv_η_ds * Δt_RT * sum(p_ds) <= Cycles * E_max)
@constraint(m, η_ch * Δt_RT * sum(p_ch) <= Cycles * E_max)

optimize!(m)

### Go through results

solution_summary(m)

using PlotlyJS

value.(eb_rt_out[T_rt]).data
value.(eb_da_out[T_da]).data

plot([scatter(x=dates_rt, y=value.(e_st[T_rt]).data, yaxis_name="SoC Battery")])
plot(value.(eb_da_out[T_da]).data - value.(eb_da_in[T_da]).data, title="eb_DA: out - in")
plot(
    (value.(eb_rt_out[T_rt]).data - value.(eb_rt_in[T_rt]).data) * 100,
    label="eb_RT: out - in",
)
plot([
    scatter(
        x=dates_da,
        y=value.(eb_da_out[T_da]).data - value.(eb_da_in[T_da]).data,
        name="eb_da: out - in",
    ),
])

dart = [λ_da[tmap[t]] - λ_rt[t] for t in T_rt]

p1 = plot([
    scatter(x=dates_rt, y=(value.(eb_rt_out[T_rt]).data), name="eb_rt: out"),
    scatter(x=dates_rt, y=-(value.(eb_rt_in[T_rt]).data), name="eb_rt: in"),
    scatter(
        x=dates_da,
        y=(value.(eb_da_out[T_da]).data),
        name="eb_da: out",
        line_shape="hv",
    ),
    scatter(
        x=dates_da,
        y=-(value.(eb_da_in[T_da]).data),
        name="eb_da: in",
        line_shape="hv",
    ),
])
p2 = plot([
    scatter(x=dates_rt, y=value.(p_re[T_rt]), name="p_re"),
    scatter(x=dates_rt, y=value.(p_th[T_rt]), name="p_th"),
    scatter(x=dates_rt, y=value.(p_ds[T_rt]), name="p_ds"),
    scatter(x=dates_rt, y=-value.(p_ch[T_rt]), name="p_ch"),
    scatter(x=dates_rt, y=-P_ld, name="P_ld"),
])
p3 = plot([
    scatter(x=dates_da, y=λ_da / 100, name="λ_DA", line_shape="hv"),
    scatter(x=dates_rt, y=λ_rt / 100, name="λ_RT", line_shape="hv"),
    scatter(x=dates_rt, y=dart / 100, name="DART", line_shape="hv"),
])
p = [p1; p2; p3]

savefig(p, "test.pdf")

dart = [λ_da[tmap[t]] - λ_rt[t] for t in T_rt]
