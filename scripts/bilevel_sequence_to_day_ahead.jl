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
using JuMP
using Statistics
const PSY = PowerSystems
const PSI = PowerSimulations
const PSB = PowerSystemCaseBuilder
const HSS = HybridSystemsSimulations

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
include("get_templates.jl")
include("modify_systems.jl")
include("price_generation_utils.jl")
include("build_simulation_cases_reserves.jl")
include("utils.jl")

## Get Systems
# Let's do three days of 24 hours each for Day Ahead given that we have prices for three days
horizon_merchant_da = 72
horizon_merchant_rt = horizon_merchant_da * 12
sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys_noForecast")
sys_rts_merchant = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")

interval_DA = Hour(24)
transform_single_time_series!(sys_rts_da, horizon_merchant_da, interval_DA)
interval_RT = Minute(5)

# sys_rts_rt = PSB.build_RTS_GMLC_RT_sys(raw_data=PSB.RTS_DIR, horizon=horizon_merchant_rt, interval=Minute(5))
add_da_forecast_in_5_mins_to_rt!(sys_rts_merchant, sys_rts_da)
transform_single_time_series!(sys_rts_merchant, horizon_merchant_rt, interval_RT)
# There is no Wind + Thermal in a Single Bus.
# We will try to pick the Wind in 317 bus Chuhsi
# It does not have thermal and load, so we will pick the adjacent bus 318: Clark
for s in [sys_rts_da, sys_rts_merchant]
    bus_to_add = "Chuhsi" # "Barton"
    modify_ren_curtailment_cost!(s)
    add_hybrid_to_chuhsi_bus!(s)
end

sys = sys_rts_merchant
sys.internal.ext = Dict{String, DataFrame}()
dic = PSY.get_ext(sys)

# Add prices to ext. Only three days.
bus_name = "chuhsi"
dic["λ_da_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic["λ_Reg_Up"] = CSV.read(
    "scripts/simulation_pipeline/inputs/$(bus_name)_RegUp_prices_new.csv",
    DataFrame,
)
dic["λ_Reg_Down"] = CSV.read(
    "scripts/simulation_pipeline/inputs/$(bus_name)_RegDown_prices_new.csv",
    DataFrame,
)
dic["λ_Spin_Up_R3"] = CSV.read(
    "scripts/simulation_pipeline/inputs/$(bus_name)_Spin_prices_new.csv",
    DataFrame,
)

hy_sys = first(get_components(HybridSystem, sys))
tmap =
    get_ext(hy_sys)["tmap"] =
        tmap = [
            div(k - 1, Int(horizon_merchant_rt / horizon_merchant_da)) + 1 for
            k in 1:horizon_merchant_rt
        ]

time_da_long = dic["λ_da_df"][!, 1]
time_rt = dic["λ_rt_df"][!, 1]
#=
services = collect(get_components(Service, sys_rts_da))
regdown = services[1]
regup = services[5]
spin = services[4]
average_price = mean(dic["λ_da_df"][!, 2])
regup_req =
    values(get_time_series(SingleTimeSeries, regup, "requirement")[time_da_long].data) *
    average_price / 1.1
regdown_req =
    values(get_time_series(SingleTimeSeries, regdown, "requirement")[time_da_long].data) *
    average_price / 3
spin_req =
    values(get_time_series(SingleTimeSeries, spin, "requirement")[time_da_long].data) *
    average_price / 1.4
regup_req[18] = 35.0
regup_req[19] = 35.0
regup_req[20] = 35.0
using CSV
df_spin = DataFrame("DateTime" => time_da_long, "Chuhsi" => spin_req)
df_up = DataFrame("DateTime" => time_da_long, "Chuhsi" => regup_req)
df_dn = DataFrame("DateTime" => time_da_long, "Chuhsi" => regdown_req)

CSV.write("scripts/simulation_pipeline/inputs/chuhsi_RegUp_prices_new.csv", df_up)
CSV.write("scripts/simulation_pipeline/inputs/chuhsi_RegDown_prices_new.csv", df_dn)
CSV.write("scripts/simulation_pipeline/inputs/chuhsi_Spin_prices_new.csv", df_spin)
=#

bus_name = "chuhsi"
dic["λ_da_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic["λ_Reg_Up"] = CSV.read(
    "scripts/simulation_pipeline/inputs/$(bus_name)_RegUp_prices_new.csv",
    DataFrame,
)
dic["λ_Reg_Down"] = CSV.read(
    "scripts/simulation_pipeline/inputs/$(bus_name)_RegDown_prices_new.csv",
    DataFrame,
)
dic["λ_Spin_Up_R3"] = CSV.read(
    "scripts/simulation_pipeline/inputs/$(bus_name)_Spin_prices_new.csv",
    DataFrame,
)

λ_rt = dic["λ_rt_df"][!, 2][1:horizon_merchant_rt]
λ_da = dic["λ_da_df"][!, 2][1:horizon_merchant_da]
λ_regup = dic["λ_Reg_Up"][!, 2][1:horizon_merchant_da]
λ_regdown = dic["λ_Reg_Down"][!, 2][1:horizon_merchant_da]
λ_spin = dic["λ_Spin_Up_R3"][!, 2][1:horizon_merchant_da]
DART = [λ_da[tmap[t]] - λ_rt[t] for t in 1:horizon_merchant_rt]

plot([
    #scatter(x = time_da_long, y = λ_da, name = "Day-Ahead", line_shape="hv"),
    #scatter(x = time_rt, y = λ_rt, name = "Real-Time", line_shape="hv"),
    scatter(x=time_rt, y=DART, name="DART", line_shape="hv"),
    scatter(x=time_da_long, y=λ_regup, name="Reg-Up Price", line_shape="hv"),
    scatter(x=time_da_long, y=λ_regdown, name="Reg-Down Price", line_shape="hv"),
    scatter(x=time_da_long, y=λ_spin, name="Spin Price", line_shape="hv"),
    #scatter(x = time_da_long, y = regup_req, name = "Reg-Up Req", line_shape = "hv"),
    #scatter(x = time_da_long, y = regdown_req, name = "Reg-Down Req", line_shape = "hv"),
    #scatter(x = time_da_long, y = spin_req, name = "Spin Req", line_shape = "hv"),
])

dic["horizon_RT"] = horizon_merchant_rt
dic["horizon_DA"] = horizon_merchant_da

hy_sys = first(get_components(HybridSystem, sys))
services = get_components(VariableReserve, sys)
served_fraction_map = Dict(
    "Spin_Up_R2" => 0.00,
    "Spin_Up_R3" => 0.00,
    "Reg_Up" => 0.3,
    "Spin_Up_R1" => 0.00,
    "Flex_Up" => 0.1,
    "Reg_Down" => 0.3,
    "Flex_Down" => 0.1,
)

for service in services
    serv_name = get_name(service)
    serv_ext = get_ext(service)
    serv_ext["served_fraction"] = served_fraction_map[serv_name]
    if contains(serv_name, "Spin_Up_R1") |
       contains(serv_name, "Spin_Up_R2") |
       contains(serv_name, "Flex")
        continue
    else
        add_service!(hy_sys, service, sys)
    end
end
PSY.set_ext!(hy_sys, deepcopy(dic))

# Set decision model for Optimizer
decision_optimizer_DA = DecisionModel(
    MerchantHybridBilevelCase,
    ProblemTemplate(CopperPlatePowerModel),
    sys,
    optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 5e-3),
    calculate_conflict=true,
    optimizer_solve_log_print=true,
    store_variable_names=true,
    check_numerical_bounds=false,
    direct_mode_optimizer=true,
    initial_time=DateTime("2020-10-03T00:00:00"),
    name="MerchantHybridCooptimizerCase_DA",
)

build!(decision_optimizer_DA; output_dir=pwd())
#bid_regup_out = decision_optimizer_DA.internal.container.variables[PSI.VariableKey{HSS.BidReserveVariableOut, VariableReserve{ReserveUp}}("Reg_Up")]
#JuMP.fix(bid_regup_out["317_Hybrid", 12], 1.0; force = true)
solve!(decision_optimizer_DA)
res_b = ProblemResults(decision_optimizer_DA)

#=
cons = decision_optimizer_DA.internal.container.constraints
cons[PowerSimulations.ConstraintKey{
    HybridSystemsSimulations.ReserveCoverageConstraintEndOfPeriod,
    HybridSystem,
}(
    "Spin_Up_R3",
)][
    "317_Hybrid",
    2,
]
cons[PowerSimulations.ConstraintKey{
    HybridSystemsSimulations.ReserveCoverageConstraint,
    HybridSystem,
}(
    "Spin_Up_R3",
)][
    "317_Hybrid",
    2,
]
cons[PowerSimulations.ConstraintKey{
    HybridSystemsSimulations.ReserveCoverageConstraintEndOfPeriod,
    HybridSystem,
}(
    "Reg_Down",
)][
    "317_Hybrid",
    2,
]
cons[PowerSimulations.ConstraintKey{
    HybridSystemsSimulations.ReserveCoverageConstraint,
    HybridSystem,
}(
    "Reg_Down",
)][
    "317_Hybrid",
    2,
]
cons[PowerSimulations.ConstraintKey{
    HybridSystemsSimulations.MarketOutConvergence,
    HybridSystem,
}(
    "",
)][
    "317_Hybrid",
    2,
]
cons[PowerSimulations.ConstraintKey{
    HybridSystemsSimulations.MarketInConvergence,
    HybridSystem,
}(
    "",
)][
    "317_Hybrid",
    2,
]

vars = decision_optimizer_DA.internal.container.variables
params = decision_optimizer_DA.internal.container.parameters
exprs = decision_optimizer_DA.internal.container.expressions

cons[PSI.ConstraintKey{HSS.DayAheadBidInRangeLimit, HybridSystem}("lb")]["317_Hybrid", 1]
cons[PSI.ConstraintKey{HSS.RealTimeBidOutRangeLimit, HybridSystem}("ub")]["317_Hybrid", 288]
cons[PSI.ConstraintKey{HSS.StatusInOn, HybridSystem}("ub")]["317_Hybrid", 288]
cons[PSI.ConstraintKey{HSS.MarketInConvergence, HybridSystem}("")]["317_Hybrid", 288]
cons[PSI.ConstraintKey{HSS.ReserveBalance, HybridSystem}("Reg_Up")]["317_Hybrid", 288]
exprs[PSI.ExpressionKey{HSS.TotalReserveInUpExpression, HybridSystem}("")]["317_Hybrid", 1]
vars[PSI.VariableKey{HSS.ThermalReserveVariable, VariableReserve{ReserveUp}}("Reg_Up")]
JuMP.upper_bound(
    vars[PSI.VariableKey{HSS.BatteryDischarge, HybridSystem}("")]["317_Hybrid", 1],
)
=#

# OUT
time_rt = read_variable(res_b, "ReservationVariable__HybridSystem")[!, 1]
hybrid_on = read_variable(res_b, "ReservationVariable__HybridSystem")[!, "317_Hybrid"]
bid_rt_out = read_variable(res_b, "EnergyRTBidOut__HybridSystem")[!, "317_Hybrid"]
p_out =
    read_variable(res_b, "ActivePowerOutVariable__HybridSystem")[!, "317_Hybrid"] / 100.0
p_in = read_variable(res_b, "ActivePowerInVariable__HybridSystem")[!, "317_Hybrid"] / 100.0
var_res_b = res_b.variable_values
time_da = dic["λ_da_df"][!, "DateTime"][1:horizon_merchant_da]
res_out_regup =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableOut, VariableReserve{ReserveUp}}(
        "Reg_Up",
    )][
        !,
        "317_Hybrid",
    ]
res_out_spin =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableOut, VariableReserve{ReserveUp}}(
        "Spin_Up_R3",
    )][
        !,
        "317_Hybrid",
    ]
res_out_down =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableOut, VariableReserve{ReserveDown}}(
        "Reg_Down",
    )][
        !,
        "317_Hybrid",
    ]

plot(
    [
        scatter(x=time_rt, y=p_out, name="Output Power", line_shape="hv"),
        scatter(x=time_rt, y=bid_rt_out, name="Bid Out", line_shape="hv"),
        scatter(x=time_da, y=res_out_regup, name="RegUp Bid Out", line_shape="hv"),
        scatter(x=time_da, y=res_out_spin, name="Spin Bid Out", line_shape="hv"),
        scatter(x=time_da, y=res_out_down, name="RegDown Bid Out", line_shape="hv"),
        scatter(x=time_rt, y=-p_in, name="Input Power", line_shape="hv"),
    ],
    Layout(title="BiLevel"),
)

# IN
bid_rt_in = read_variable(res_b, "EnergyRTBidIn__HybridSystem")[!, "317_Hybrid"]
res_in_regup =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableIn, VariableReserve{ReserveUp}}(
        "Reg_Up",
    )][
        !,
        "317_Hybrid",
    ]
res_in_spin =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableIn, VariableReserve{ReserveUp}}(
        "Spin_Up_R3",
    )][
        !,
        "317_Hybrid",
    ]
res_in_down =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableIn, VariableReserve{ReserveDown}}(
        "Reg_Down",
    )][
        !,
        "317_Hybrid",
    ]

plot(
    [
        scatter(x=time_rt, y=p_in, name="Input Power", line_shape="hv"),
        scatter(x=time_rt, y=bid_rt_in, name="Bid In", line_shape="hv"),
        scatter(x=time_da, y=res_in_regup, name="RegUp Bid In", line_shape="hv"),
        scatter(x=time_da, y=res_in_spin, name="Spin Bid In", line_shape="hv"),
        scatter(x=time_da, y=res_in_down, name="RegDown Bid In", line_shape="hv"),
        #scatter(x = time_rt, y = -p_in, name = "Input Power", line_shape = "hv")
    ],
    Layout(title="BiLevel"),
)

# Assets
p_re_asset =
    read_parameter(res_b, "RenewablePowerTimeSeries__HybridSystem")[!, "317_Hybrid"]
#p_load = read_parameter(res_b, "ElectricLoadTimeSeries__HybridSystem")[!, "317_Hybrid"]
p_re = read_variable(res_b, "RenewablePower__HybridSystem")[!, "317_Hybrid"]
p_th = read_variable(res_b, "ThermalPower__HybridSystem")[!, "317_Hybrid"]
p_ch = read_variable(res_b, "BatteryCharge__HybridSystem")[!, "317_Hybrid"]
p_ds = read_variable(res_b, "BatteryDischarge__HybridSystem")[!, "317_Hybrid"]
soc = read_variable(res_b, "EnergyVariable__HybridSystem")[!, "317_Hybrid"] / 100.0
plot(
    [
        #scatter(x=time_rt, y=-p_in, name="Input Power", line_shape="hv"),
        scatter(x=time_rt, y=p_out, name="Output Power", line_shape="hv"),
        #scatter(x=time_rt, y=p_th, name="Thermal Power", line_shape="hv"),
        #scatter(x=time_rt, y=p_re, name="Renewable Power", line_shape="hv"),
        #scatter(x=time_rt, y=p_re_asset, name="Renewable Available", line_shape="hv"),
        scatter(x=time_rt, y=-p_ch, name="Charge Power", line_shape="hv"),
        scatter(x=time_rt, y=p_ds, name="Discharge Power", line_shape="hv"),
        scatter(x=time_rt, y=soc, name="State of Charge", line_shape="hv"),
        #scatter(x=time_rt, y=λ_rt, name="RT Price", yaxis="y2", line_shape="hv"),
    ],
    Layout(
        title="BiLevel",
        xaxis_title="Time",
        yaxis_title="Power [pu]",
        #=
        yaxis2=attr(
            title="Price [\$/MWh]",
            overlaying="y",
            side="right",
            autorange=false,
            range=[-35, 35],
        ),
        =#
    ),
)

#Day AHead
da_bid_out =
    var_res_b[PSI.VariableKey{HSS.EnergyDABidOut, HybridSystem}("")][!, "317_Hybrid"]
da_bid_in = var_res_b[PSI.VariableKey{HSS.EnergyDABidIn, HybridSystem}("")][!, "317_Hybrid"]

plot(
    [
        scatter(x=time_da, y=da_bid_out, name="DA Bid Out", line_shape="hv"),
        scatter(x=time_da, y=res_out_regup, name="RegUp Out", line_shape="hv"),
        scatter(
            x=time_da,
            y=res_out_down,
            name="RegDown Out",
            line_shape="hv",
            line=attr(dash="dash"),
        ),
        scatter(x=time_da, y=res_out_spin, name="Spin Out", line_shape="hv"),
        scatter(x=time_da, y=-da_bid_in, name="DA Bid In", line_shape="hv"),
        scatter(x=time_rt, y=DART, name="DART", line_shape="hv"),
    ],
    Layout(title="BiLevel"),
)

##############################
###### Scripts Plot New ######
##############################

hy_sys = first(get_components(HybridSystem, sys))
tmap = get_ext(hy_sys)["tmap"]
res = ProblemResults(decision_optimizer_DA)

λ_rt = dic["λ_rt_df"][!, 2][1:horizon_merchant_rt]
λ_da = dic["λ_da_df"][!, 2][1:horizon_merchant_da]
λ_regup = dic["λ_Reg_Up"][!, 2][1:horizon_merchant_da]
λ_regdown = dic["λ_Reg_Down"][!, 2][1:horizon_merchant_da]
λ_spin = dic["λ_Spin_Up_R3"][!, 2][1:horizon_merchant_da]
DART = [λ_da[tmap[t]] - λ_rt[t] for t in 1:horizon_merchant_rt]

plot([
    scatter(x=time_da, y=λ_da, name="DA", line_shape="hv"),
    scatter(x=time_rt, y=λ_rt, name="RT", line_shape="hv"),
    scatter(x=time_rt, y=DART, name="DART", line_shape="hv"),
])

# OUT
time_rt = read_variable(res_b, "ReservationVariable__HybridSystem")[!, 1]
hybrid_on = read_variable(res_b, "ReservationVariable__HybridSystem")[!, "317_Hybrid"]
bid_rt_out = read_variable(res_b, "EnergyRTBidOut__HybridSystem")[!, "317_Hybrid"]
p_out =
    read_variable(res_b, "ActivePowerOutVariable__HybridSystem")[!, "317_Hybrid"] / 100.0
p_in = read_variable(res_b, "ActivePowerInVariable__HybridSystem")[!, "317_Hybrid"] / 100.0
var_res_b = res_b.variable_values
time_da = dic["λ_da_df"][!, "DateTime"][1:horizon_merchant_da]
res_out_regup =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableOut, VariableReserve{ReserveUp}}(
        "Reg_Up",
    )][
        !,
        "317_Hybrid",
    ]
res_out_spin =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableOut, VariableReserve{ReserveUp}}(
        "Spin_Up_R3",
    )][
        !,
        "317_Hybrid",
    ]
res_out_down =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableOut, VariableReserve{ReserveDown}}(
        "Reg_Down",
    )][
        !,
        "317_Hybrid",
    ]

res_in_down =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableIn, VariableReserve{ReserveDown}}(
        "Reg_Down",
    )][
        !,
        "317_Hybrid",
    ]

plot(
    [
        scatter(x=time_rt, y=p_out[1:277], name="Output Power", line_shape="hv"),
        scatter(x=time_rt, y=bid_rt_out[1:277], name="Bid Out", line_shape="hv"),
        scatter(x=time_da, y=0.25 * res_out_regup, name="RegUp Bid Out", line_shape="hv"),
        scatter(x=time_da, y=0.25 * res_out_spin, name="Spin Bid Out", line_shape="hv"),
        scatter(x=time_da, y=0.25 * res_out_down, name="RegDown Bid Out", line_shape="hv"),
        scatter(x=time_rt, y=-p_in[1:277], name="Input Power", line_shape="hv"),
    ],
    Layout(xaxis_title="Time", yaxis_title="Power and Bids [pu]"),
)

# IN
bid_rt_in = read_variable(res_b, "EnergyRTBidIn__HybridSystem")[!, "317_Hybrid"]
res_in_regup =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableIn, VariableReserve{ReserveUp}}(
        "Reg_Up",
    )][
        !,
        "317_Hybrid",
    ]
res_in_spin =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableIn, VariableReserve{ReserveUp}}(
        "Spin_Up_R3",
    )][
        !,
        "317_Hybrid",
    ]
res_in_down =
    var_res_b[PSI.VariableKey{HSS.BidReserveVariableIn, VariableReserve{ReserveDown}}(
        "Reg_Down",
    )][
        !,
        "317_Hybrid",
    ]

plot(
    [
        scatter(x=time_rt, y=p_in, name="Input Power", line_shape="hv"),
        scatter(x=time_rt, y=bid_rt_in, name="Bid In", line_shape="hv"),
        scatter(x=time_da, y=0.25 * res_in_regup, name="RegUp Bid In", line_shape="hv"),
        scatter(x=time_da, y=0.25 * res_in_spin, name="Spin Bid In", line_shape="hv"),
        scatter(x=time_da, y=0.25 * res_in_down, name="RegDown Bid In", line_shape="hv"),
        #scatter(x = time_rt, y = -p_in, name = "Input Power", line_shape = "hv")
    ],
    Layout(xaxis_title="Time", yaxis_title="Power and Bids [pu]"),
)

# Assets
p_re_asset =
    read_parameter(res_b, "RenewablePowerTimeSeries__HybridSystem")[!, "317_Hybrid"]
# p_load = read_parameter(res_b, "ElectricLoadTimeSeries__HybridSystem")[!, "317_Hybrid"]
p_re = read_variable(res_b, "RenewablePower__HybridSystem")[!, "317_Hybrid"]
p_th = read_variable(res_b, "ThermalPower__HybridSystem")[!, "317_Hybrid"]
p_ch = read_variable(res_b, "BatteryCharge__HybridSystem")[!, "317_Hybrid"]
p_ds = read_variable(res_b, "BatteryDischarge__HybridSystem")[!, "317_Hybrid"]
soc = read_variable(res_b, "EnergyVariable__HybridSystem")[!, "317_Hybrid"] / 100.0
plot(
    [
        scatter(x=time_rt, y=-p_in, name="Input Power", line_shape="hv"),
        scatter(x=time_rt, y=p_out, name="Output Power", line_shape="hv"),
        scatter(x=time_rt, y=p_th, name="Thermal Power", line_shape="hv"),
        scatter(x=time_rt, y=p_re, name="Renewable Power", line_shape="hv"),
        scatter(x=time_rt, y=p_re_asset, name="Renewable Available", line_shape="hv"),
        scatter(x=time_rt, y=-p_ch, name="Charge Power", line_shape="hv"),
        scatter(x=time_rt, y=p_ds, name="Discharge Power", line_shape="hv"),
        scatter(x=time_rt, y=soc, name="State of Charge", line_shape="hv"),
        scatter(x=time_rt, y=λ_rt, name="RT Price", yaxis="y2", line_shape="hv"),
    ],
    Layout(
        xaxis_title="Time",
        yaxis_title="Power [pu]",
        yaxis2=attr(
            title="Price [\$/MWh]",
            overlaying="y",
            side="right",
            autorange=false,
            range=[-35, 35],
        ),
    ),
)

#Day AHead
da_bid_out =
    var_res_b[PSI.VariableKey{HSS.EnergyDABidOut, HybridSystem}("")][!, "317_Hybrid"]
da_bid_in = var_res_b[PSI.VariableKey{HSS.EnergyDABidIn, HybridSystem}("")][!, "317_Hybrid"]

plot(
    [
        scatter(x=time_da, y=da_bid_out, name="DA Bid Out", line_shape="hv"),
        scatter(x=time_da, y=-da_bid_in, name="DA Bid In", line_shape="hv"),
        scatter(x=time_rt[1:277], y=DART[1:277] / 4, name="DART / 4", line_shape="hv"),
    ],
    Layout(
        title="Bi-level",
        xaxis_title="Time",
        yaxis_title="Power [pu] and Price [\$/MWh]",
    ),
)

# Asset Reserve

res_re_regup =
    read_variable(res_b, "RenewableReserveVariable__VariableReserve__ReserveUp__Reg_Up")[
        !,
        "317_Hybrid",
    ]
res_re_spin =
    read_variable(res_b, "RenewableReserveVariable__VariableReserve__ReserveUp__Spin_Up_R3")[
        !,
        "317_Hybrid",
    ]
res_re_regdown =
    read_variable(res_b, "RenewableReserveVariable__VariableReserve__ReserveDown__Reg_Down")[
        !,
        "317_Hybrid",
    ]
res_ds_regdown = read_variable(
    res_b,
    "DischargingReserveVariable__VariableReserve__ReserveDown__Reg_Down",
)[
    !,
    "317_Hybrid",
]
res_ch_regdown =
    read_variable(res_b, "ChargingReserveVariable__VariableReserve__ReserveDown__Reg_Down")[
        !,
        "317_Hybrid",
    ]
res_th_regdown =
    read_variable(res_b, "ThermalReserveVariable__VariableReserve__ReserveDown__Reg_Down")[
        !,
        "317_Hybrid",
    ]

plot(
    [
        scatter(x=time_da, y=0.25 * res_out_down, name="RegDown Bid Out", line_shape="hv"),
        scatter(x=time_da, y=0.25 * res_in_down, name="RegDown Bid In", line_shape="hv"),
        scatter(
            x=time_rt,
            y=0.25 * res_re_regdown[1:277],
            name="RegDown Re Bid Out",
            line_shape="hv",
        ),
        scatter(
            x=time_rt,
            y=0.25 * res_ch_regdown[1:277],
            name="RegDown Ch Bid Out",
            line_shape="hv",
        ),
        scatter(
            x=time_rt,
            y=0.25 * res_ds_regdown[1:277],
            name="RegDown Ds Bid Out",
            line_shape="hv",
        ),
    ],
    Layout(xaxis_title="Time", yaxis_title="Power and Bids [pu]"),
)

plot(
    [
        scatter(
            x=time_da,
            y=0.25 * res_out_down + 0.25 * res_in_down,
            name="RegDown Bid",
            line_shape="hv",
        ),
        scatter(
            x=time_rt,
            y=0.25 * res_th_regdown[1:277] +
              0.25 * res_re_regdown[1:277] +
              0.25 * res_ch_regdown[1:277] +
              0.25 * res_ds_regdown[1:277],
            name="RegDown Re Bid Out",
            line_shape="hv",
        ),
    ],
    Layout(xaxis_title="Time", yaxis_title="Power and Bids [pu]"),
)

plot(
    [
        #scatter(x=time_rt, y=0.25*res_th_regdown[1:277], name="RegDown Th Bid Out", line_shape="hv", stackgroup="one", mode="lines", hoverinfo="x+y",),
        scatter(
            x=time_rt,
            y=0.25 * res_re_regdown[1:277],
            name="RegDown Re Bid Out",
            line_shape="hv",
            stackgroup="one",
            mode="lines",
            hoverinfo="x+y",
        ),
        scatter(
            x=time_rt,
            y=0.25 * res_ch_regdown[1:277],
            name="RegDown Ch Bid Out",
            line_shape="hv",
            stackgroup="one",
            mode="lines",
            hoverinfo="x+y",
        ),
        scatter(
            x=time_rt,
            y=0.25 * res_ds_regdown[1:277],
            name="RegDown Ds Bid Out",
            line_shape="hv",
            stackgroup="one",
            mode="lines",
            hoverinfo="x+y",
        ),
        scatter(
            x=time_da,
            y=0.25 * (res_out_down + res_in_down),
            name="RegDown Bid Total",
            line_shape="hv",
            line=attr(color="black", dash="dash"),
        ),
    ],
    Layout(xaxis_title="Time", yaxis_title="Bids [pu]"),
)

#=
plot([
    scatter(x=time_da, y=-0.25*res_out_down, name="RegDown Bid Out", line_shape="hv"),
    scatter(x=time_rt, y=bid_rt_out[1:277], name="Bid Out", line_shape="hv", stackgroup="one", mode="lines", hoverinfo="x+y"),
    scatter(x=time_da, y=0.25*res_out_regup, name="RegUp Bid Out", line_shape="hv", stackgroup="one", mode="lines", hoverinfo="x+y"),
    scatter(x=time_rt, y=p_out[1:277], name="Output Power", line_shape="hv", line=attr(color="black", dash="dash"),),
],  Layout(
    xaxis_title="Time",
    yaxis_title="Power and Bids [pu]",
),
)
=#

reg_down_served = [res_out_down[tmap[t]] for t in 1:length(time_rt)]

plot(
    [
        scatter(
            x=time_rt,
            y=p_out,
            name="Output Power",
            line_shape="hv",
            stackgroup="one",
            mode="lines",
            hoverinfo="x+y",
        ),
        scatter(
            x=time_rt,
            y=0.25 * reg_down_served,
            name="RegDown Served Energy",
            line_shape="hv",
            stackgroup="one",
            mode="lines",
            hoverinfo="x+y",
        ),
        scatter(
            x=time_rt,
            y=bid_rt_out,
            name="Bid Out",
            line_shape="hv",
            line=attr(color="black", dash="dash"),
        ),
    ],
    Layout(xaxis_title="Time", yaxis_title="Power and Bids [pu]"),
)
