# Load SIIP Packages
using PowerSimulations
using PowerSystems
using PowerSystemCaseBuilder
using InfrastructureSystems
using PowerNetworkMatrices
using HybridSystemsSimulations
using HydroPowerSimulations
using StorageSystemsSimulations
import OrderedCollections: OrderedDict
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
using DataFrames

result_folder = joinpath(
    @__DIR__,
    "../..",
    "centralized_sim_HybridDispatchWithReserves_2020-07-10T00:00:00",
)

results_dcp = SimulationResults(result_folder; ignore_status=true)

results_ed_dcp = get_decision_problem_results(results_dcp, "ED")
results_uc_dcp = get_decision_problem_results(results_dcp, "UC")

p_re_da = read_realized_variable(results_uc_dcp, "RenewablePower__HybridSystem")[!, 2]
p_re_da_param = read_realized_parameter(results_uc_dcp, "RenewablePowerTimeSeries__HybridSystem")[!, 2]
p_re = read_realized_variable(results_ed_dcp, "RenewablePower__HybridSystem")[!, 2]
p_re_param = read_realized_parameter(results_ed_dcp, "RenewablePowerTimeSeries__HybridSystem")[!, 2]
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
slackup = read_realized_variable(results_ed_dcp, "SystemBalanceSlackUp__System")
#p_load =
#    read_realized_parameter(results_ed_dcp, "ElectricLoadTimeSeries__HybridSystem")[!, 2]
#p_asset = read_realized_variable(results_uc_dcp, "ActivePowerVariable__HybridSystem")

dates_uc = read_realized_dual(results_uc_dcp, "CopperPlateBalanceConstraint__System")[!, 1]
dates_ed = read_realized_dual(results_ed_dcp, "CopperPlateBalanceConstraint__System")[!, 1]
prices_uc_dcp =
    read_realized_dual(results_uc_dcp, "CopperPlateBalanceConstraint__System")[!, 2] ./
    100.0
prices_ed_dcp =
    read_realized_dual(results_ed_dcp, "CopperPlateBalanceConstraint__System")[!, 2] ./
    100.0 * 60 / 5

prices_ed_dcp = clamp.(prices_ed_dcp, -100.0, 100.0)

T_da = 1:length(dates_uc)
T_rt = 1:length(dates_ed)
tmap = [div(k - 1, Int(length(T_rt) / length(T_da))) + 1 for k in T_rt]
dart = [prices_uc_dcp[tmap[t]] - prices_ed_dcp[t] for t in T_rt]

ixs_da = 1:24*7
ixs_rt = 1:24*7*12
fig = plot([
    scatter(x=dates_uc[ixs_da], y=prices_uc_dcp[ixs_da], name="DA Prices", line_shape="hv", line_color = "blue"),
    scatter(x=dates_ed[ixs_rt], y=prices_ed_dcp[ixs_rt], name="RT Prices", line_shape="hv", line_color = "red", line=attr(dash="dot")),
],
    Layout(
        yaxis_title="Energy Prices [\$/MWh]",
        template="simply_white",
        legend=attr(x=0.01, y=0.98, font_size=14, bordercolor="Black", borderwidth=1),
    ),
)

savefig(fig, "scripts/flexpower_rts/figs/prices_centralized_jul.pdf")


p3 = plot(
    [
        scatter(
            x=dates_uc[ixs_da],
            y=p_re_da[ixs_da],
            name="DA Hybrid Sys. Renewable Power",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="cyan",
        ),
        scatter(
            x=dates_uc[ixs_da],
            y=p_re_da_param[ixs_da],
            name="DA Hybrid Sys. Available Renewable",
            line_shape="hv",
            line_color = "blue",
        ),
        scatter(
            x=dates_ed[ixs_rt],
            y=p_re[ixs_rt],
            name="RT Hybrid Sys. Renewable Power",
            line_shape="hv",
            mode="none",
            stackgroup="one",
            #fillcolor="lightgreen",
            fillpattern = attr(fgcolor = "orange", fgopacity = 0.5),
        ),
        scatter(
            x=dates_ed[ixs_rt],
            y=p_re_param[ixs_rt],
            name="RT Hybrid Sys. Available Renewable",
            line_shape="hv",
            line_color = "darkgreen",
        ),
    ],
    Layout(
        yaxis_title="Power [x100 MW]",
        template="simply_white",
        legend=attr(x=0.03, y=1.1, font_size=14, bordercolor="Black", borderwidth=1),
    ),
)

savefig(p3, "scripts/flexpower_rts/figs/renew_centr_jul.pdf")

fig2 = plot([
    scatter(x=dates_ed, y=slackup[!, 2], name="SlackUp", line_shape="hv"),
    scatter(x=dates_ed, y=prices_ed_dcp, name="λ_RT", line_shape="hv"),
])

DA_prices = DataFrame()
DA_prices[!, "DateTime"] = dates_uc
DA_prices[!, "Chuhsi"] = prices_uc_dcp

RT_prices = DataFrame()
RT_prices[!, "DateTime"] = dates_ed
RT_prices[!, "Chuhsi"] = prices_ed_dcp

# AS Prices Temporary Hack
reg_up = abs.(DA_prices[!, 2] / 10.0)
reg_dn = abs.(DA_prices[!, 2] / 12.0)
reg_spin = abs.(DA_prices[!, 2] / 25.0)

dates = DA_prices[!, 1]
df_spin = DataFrame("DateTime" => dates, "Chuhsi" => reg_spin)
df_up = DataFrame("DateTime" => dates, "Chuhsi" => reg_up)
df_dn = DataFrame("DateTime" => dates, "Chuhsi" => reg_dn)

