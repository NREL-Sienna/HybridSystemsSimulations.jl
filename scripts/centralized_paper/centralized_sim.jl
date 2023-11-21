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
using DataFrames
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

sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys_noForecast")

# There is no Wind + Thermal in a Single Bus.
# We will try to pick the Wind in 317 bus Chuhsi
# It does not have thermal and load, so we will pick the adjacent bus 318: Clark
bus_to_add = "Chuhsi" # "Barton"
modify_ren_curtailment_cost!(sys_rts_da)
add_hybrid_to_chuhsi_bus!(sys_rts_da)

#interval_DA = Hour(24)
#horizon_DA = 72
interval_DA = Hour(72)
horizon_DA = 72
transform_single_time_series!(sys_rts_da, horizon_DA, interval_DA)
#########################################
######## Add Services to Hybrid #########
#########################################

served_fraction_map = Dict(
    "Spin_Up_R2" => 0.00,
    "Spin_Up_R3" => 0.00,
    "Reg_Up" => 0.3,
    "Spin_Up_R1" => 0.00,
    "Flex_Up" => 0.1,
    "Reg_Down" => 0.3,
    "Flex_Down" => 0.1,
)

for sys in [sys_rts_da]
    services = get_components(VariableReserve, sys)
    hy_sys = first(get_components(HybridSystem, sys))
    for service in services
        serv_name = get_name(service)
        serv_ext = get_ext(service)
        serv_frac = served_fraction_map[serv_name]
        serv_ext["served_fraction"] = serv_frac
        set_deployed_fraction!(service, serv_frac)
        if contains(serv_name, "Spin_Up_R1") |
           contains(serv_name, "Spin_Up_R2") |
           contains(serv_name, "Flex")
            continue
        else
            add_service!(hy_sys, service, sys)
        end
    end
end

###############################
###### Create Templates #######
###############################

# CopperPlate
template_uc_copperplate = get_uc_copperplate_template(sys_rts_da)

# PTDF Bounded
template_uc_ptdf = get_uc_ptdf_template(sys_rts_da)

# PTDF Unbounded
template_uc_unbounded_ptdf = get_uc_ptdf_unbounded_template(sys_rts_da)

# DCP
template_uc_dcp = get_uc_dcp_template()

set_device_model!(
    template_uc_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "storage_reservation" => true,
            "energy_target" => true,
            "cycling" => true,
        ),
    ),
)

###############################
##### Run DCP Simulation ######
###############################

mipgap = 1.0e-2

model = DecisionModel(
    template_uc_copperplate,
    sys_rts_da;
    name="UC",
    optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => mipgap),
    system_to_file=false,
    initialize_model=true,
    optimizer_solve_log_print=true,
    direct_mode_optimizer=true,
    rebuild_model=false,
    store_variable_names=true,
    #check_numerical_bounds=false,
)

PSI.build!(model, output_dir=mktempdir())

PSI.solve!(model)

res = ProblemResults(model)

techs = ["STEAM", "CT", "CC", "WIND", "NUCLEAR", "PV", "RTPV", "HYDRO", "HYBRID"]
tot_dict = Dict()
for t in techs
    tot_dict[t] = zeros(72)
end
p_th = read_variable(res, "ActivePowerVariable__ThermalStandard")
th_names = DataFrames.names(p_th[!, 2:end])
for (ix, col) in enumerate(eachcol(p_th[!, 2:end]))
    name = th_names[ix]
    tech = split(name, "_")[2]
    #println(name)
    tot_dict[tech] += col
end
p_re = read_variable(res, "ActivePowerVariable__RenewableDispatch")
re_names = DataFrames.names(p_re[!, 2:end])
for (ix, col) in enumerate(eachcol(p_re[!, 2:end]))
    name = re_names[ix]
    tech = split(name, "_")[2]
    #println(name)
    tot_dict[tech] += col
end

p_re_fix = read_parameter(res, "ActivePowerTimeSeriesParameter__RenewableFix")
re_fix_names = DataFrames.names(p_re_fix[!, 2:end])
for (ix, col) in enumerate(eachcol(p_re_fix[!, 2:end]))
    name = re_fix_names[ix]
    tech = split(name, "_")[2]
    #println(name)
    tot_dict[tech] += col
end

p_hy = read_parameter(res, "ActivePowerTimeSeriesParameter__HydroDispatch")
hy_names = DataFrames.names(p_hy[!, 2:end])
for (ix, col) in enumerate(eachcol(p_hy[!, 2:end]))
    name = hy_names[ix]
    tech = split(name, "_")[2]
    println(name)
    tot_dict[tech] += col
end

p_hyb_out = read_variable(res, "ActivePowerOutVariable__HybridSystem")
p_hyb_in = read_variable(res, "ActivePowerInVariable__HybridSystem")
hyb_names = ["317_Hybrid"]
for (ix, col) in enumerate(eachcol(p_hyb_out[!, 2:end]))
    name = hyb_names[ix]
    tech = "HYBRID"
    println(name)
    tot_dict[tech] += col
end
for (ix, col) in enumerate(eachcol(p_hyb_in[!, 2:end]))
    name = hyb_names[ix]
    tech = "HYBRID"
    println(name)
    tot_dict[tech] -= col
end

df = DataFrame()
for t in techs
    df[!, t] = tot_dict[t]
end

using CSV

CSV.write("centralized_res.csv", df)

p_load = read_parameter(res, "ActivePowerTimeSeriesParameter__PowerLoad")
tot_load = zeros(72)
for col in eachcol(p_load[!, 2:end])
    tot_load += col
end

dates_uc = p_re[!, 1]

# Power
p_hyb_out = read_variable(res, "ActivePowerOutVariable__HybridSystem")
p_hyb_in = read_variable(res, "ActivePowerInVariable__HybridSystem")
p_re_hyb = read_variable(res, "RenewablePower__HybridSystem")
p_th_hyb = read_variable(res, "ThermalPower__HybridSystem")
p_ch_hyb = read_variable(res, "BatteryCharge__HybridSystem")
p_ds_hyb = read_variable(res, "BatteryDischarge__HybridSystem")
p_re_param_hyb = read_parameter(res, "RenewablePowerTimeSeries__HybridSystem")

# RegUp
regup_out = read_variable(res, "ReserveVariableOut__VariableReserve__ReserveUp__Reg_Up")
regup_in = read_variable(res, "ReserveVariableIn__VariableReserve__ReserveUp__Reg_Up")

# SpinUp
spinup_out =
    read_variable(res, "ReserveVariableOut__VariableReserve__ReserveUp__Spin_Up_R3")
spinup_in = read_variable(res, "ReserveVariableIn__VariableReserve__ReserveUp__Spin_Up_R3")

# RegDown
regdown_out =
    read_variable(res, "ReserveVariableOut__VariableReserve__ReserveDown__Reg_Down")
regdown_in = read_variable(res, "ReserveVariableIn__VariableReserve__ReserveDown__Reg_Down")

p_hybrid = (p_hyb_out[!, 2] - p_hyb_in[!, 2]) / 100.0
p_energy_asset = p_th_hyb[!, 2] + p_re_hyb[!, 2] + p_ds_hyb[!, 2] - p_ch_hyb[!, 2]
p_reserves =
    +0.3 * regup_out[!, 2] - 0.3 * regup_in[!, 2] - 0.3 * regdown_out[!, 2] +
    0.3 * regdown_in[!, 2]
p_hybrid - p_energy_asset - p_reserves

tot_reg_down = -0.3 * regdown_out[!, 2] + 0.3 * regdown_in[!, 2]

p_hybrid
ixs_pos = [ix for (ix, val) in enumerate(p_hybrid) if val > 0.0]
ixs_neg = [ix for (ix, val) in enumerate(p_hybrid) if val <= 0.0]

p_hybrid_pos = deepcopy(p_hybrid)
p_energy_asset_pos = deepcopy(p_energy_asset)
p_reserves_pos = deepcopy(p_reserves)

p_hybrid_pos[ixs_neg] .= 0.0
p_energy_asset_pos[ixs_neg] .= 0.0
p_reserves_pos[ixs_neg] .= 0.0

p3 = plot(
    [
        scatter(
            x=dates_uc,
            y=p_re_hyb[!, 2],
            name="Hybrid Sys. Renewable",
            line_shape="hv",
            line_color="cyan",
        ),
        scatter(
            x=dates_uc,
            y=p_th_hyb[!, 2],
            name="Hybrid Sys. Thermal",
            line_shape="hv",
            line_color="rosybrown",
        ),
        scatter(
            x=dates_uc,
            y=p_ds_hyb[!, 2] - p_ch_hyb[!, 2],
            name="Hybrid Sys. Net Storage",
            line_shape="hv",
            line_color="orange",
        ),
        scatter(
            x=dates_uc,
            y=p_energy_asset,
            name="Hybrid Total Asset Power",
            line_shape="hv",
            line_color="blue",
            line=attr(dash="dot"),
        ),
    ],
    Layout(
        yaxis_title="x100 MW",
        template="simply_white",
        legend=attr(x=0.01, y=1.25, font_size=14, bordercolor="Black", borderwidth=1),
    ),
)

savefig(p3, "energy_hybrid.pdf")

soc = read_variable(res, "EnergyVariable__HybridSystem")

p1 = plot(
    [
        scatter(
            x=dates_uc,
            y=p_ds_hyb[!, 2] - p_ch_hyb[!, 2],
            name="Hybrid Sys. Net Storage",
            line_shape="hv",
            line_color="orange",
        ),
        scatter(
            x=dates_uc,
            y=soc[!, 2] / 100,
            name="State of Charge",
            yaxis="y2",
            line_shape="hv",
            line_color="blue",
        ),
    ],
    Layout(
        #xaxis_title="Time",
        yaxis_title="Power [x100 MW]",
        yaxis2=attr(
            title="Energy [x100 MWh]",
            overlaying="y",
            side="right",
            autorange=false,
            range=[-0.05, 4.05],
        ),
        template="simply_white",
        legend=attr(x=0.01, y=1.15, font_size=14, bordercolor="Black", borderwidth=1),
    ),
)

savefig(p1, "soc.pdf")

reg_dn_out =
    read_variable(res, "ActivePowerReserveVariable__VariableReserve__ReserveDown__Reg_Down")[
        !,
        "317_Hybrid",
    ] / 100.0
reg_dn_re =
    read_variable(res, "RenewableReserveVariable__VariableReserve__ReserveDown__Reg_Down")[
        !,
        2,
    ]
reg_dn_ch =
    read_variable(res, "ChargingReserveVariable__VariableReserve__ReserveDown__Reg_Down")[
        !,
        2,
    ]
reg_dn_ds =
    read_variable(res, "DischargingReserveVariable__VariableReserve__ReserveDown__Reg_Down")[
        !,
        2,
    ]
reg_dn_th =
    read_variable(res, "ThermalReserveVariable__VariableReserve__ReserveDown__Reg_Down")[
        !,
        2,
    ]

p4 = plot(
    [
        scatter(
            x=dates_uc,
            y=reg_dn_th,
            name="Reg Down Thermal",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="black",
        ),
        scatter(
            x=dates_uc,
            y=reg_dn_re,
            name="Reg Down Renewable",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="cyan",
        ),
        scatter(
            x=dates_uc,
            y=reg_dn_ds,
            name="Reg Down Discharge St.",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="peachpuf",
        ),
        scatter(
            x=dates_uc,
            y=reg_dn_ch,
            name="Reg Down Charge St.",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="orange",
        ),
        scatter(
            x=dates_uc,
            y=reg_dn_out,
            name="Reg Down Total",
            line_shape="hv",
            line_color="blue",
        ),
    ],
    Layout(
        yaxis_title="x100 MW",
        template="simply_white",
        legend=attr(x=0.01, y=1.0, font_size=14, bordercolor="Black", borderwidth=1),
    ),
)

savefig(p4, "reg_down.pdf")

reg_up_out =
    read_variable(res, "ActivePowerReserveVariable__VariableReserve__ReserveUp__Reg_Up")[
        !,
        "317_Hybrid",
    ] / 100.0
reg_up_re =
    read_variable(res, "RenewableReserveVariable__VariableReserve__ReserveUp__Reg_Up")[!, 2]
reg_up_ch =
    read_variable(res, "ChargingReserveVariable__VariableReserve__ReserveUp__Reg_Up")[!, 2]
reg_up_ds =
    read_variable(res, "DischargingReserveVariable__VariableReserve__ReserveUp__Reg_Up")[
        !,
        2,
    ]
reg_up_th =
    read_variable(res, "ThermalReserveVariable__VariableReserve__ReserveUp__Reg_Up")[!, 2]

p5 = plot(
    [
        scatter(
            x=dates_uc,
            y=reg_up_th,
            name="Reg Up Thermal",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="black",
        ),
        scatter(
            x=dates_uc,
            y=reg_up_re,
            name="Reg Up Renewable",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="cyan",
        ),
        scatter(
            x=dates_uc,
            y=reg_up_ds,
            name="Reg Up Discharge St.",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="peachpuf",
        ),
        scatter(
            x=dates_uc,
            y=reg_up_ch,
            name="Reg Up Charge St.",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="orange",
        ),
        scatter(
            x=dates_uc,
            y=reg_up_out,
            name="Reg Up Total",
            line_shape="hv",
            line_color="blue",
        ),
    ],
    Layout(
        yaxis_title="x100 MW",
        template="simply_white",
        legend=attr(x=0.01, y=1.29, font_size=14, bordercolor="Black", borderwidth=1),
    ),
)

savefig(p5, "reg_up.pdf")

re_param = read_parameter(res, "ActivePowerTimeSeriesParameter__RenewableDispatch")
re_power = read_variable(res, "ActivePowerVariable__RenewableDispatch")

tot_re_param = zeros(72)
tot_re_power = zeros(72)
for col in eachcol(re_param[!, 2:end])
    tot_re_param .+= col
end

for col in eachcol(re_power[!, 2:end])
    tot_re_power .+= col
end

plot(tot_re_param - tot_re_power)

p3 = plot(
    [
        #scatter(
        #    x=da_rt_price_forecast[!, "DateTime"],
        #    y=da_rt_price_forecast[!, 2],
        #    name="Centralized RT Price",
        #    line_shape="hv",
        #),
        #scatter(
        #    x=dates_uc,
        #    y=-p_hyb_in[!, 2] / 100.0,
        #    name="Hybrid Sys. In Power",
        #    line_shape="hv",
        #    line_color="red",
        #),
        #scatter(
        #    x=da_rt_soc[!, "DateTime"],
        #    y=da_rt_soc[!, 2] / 100.0,
        #    name="DA SoC",
        #    line_shape="hv",
        #),
        #scatter(
        #    x=dates_uc,
        #    y=-p_ch_hyb[!,2],
        #    name="Hybrid Sys. Storage Charge",
        #    line_shape="hv",
        #    mode="none",
        #    stackgroup="two",
        #    fillcolor="orange",
        #),
        scatter(
            x=dates_uc,
            y=p_re_hyb[!, 2],
            name="Hybrid Sys. Renewable Power",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="cyan",
        ),
        scatter(
            x=dates_uc,
            y=p_th_hyb[!, 2],
            name="Hybrid Sys. Thermal Power",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="rosybrown",
        ),
        scatter(
            x=dates_uc,
            y=p_reserves,
            name="Deployed Reserves (Up + Down)",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="orange",
        ),
        scatter(
            x=dates_uc,
            y=p_ds_hyb[!, 2] - p_ch_hyb[!, 2],
            name="Hybrid Sys. Storage Net",
            line_shape="hv",
            mode="none",
            stackgroup="two",
            fillcolor="peachpuff",
        ),
        scatter(
            x=dates_uc,
            y=(p_hyb_out[!, 2] - p_hyb_in[!, 2]) / 100.0,
            name="Hybrid Sys. Out Power",
            line_shape="hv",
            line_color="blue",
        ),
    ],
    Layout(
        yaxis_title="x100 MW",
        template="simply_white",
        legend=attr(x=0.01, y=1.0, font_size=14, bordercolor="Black", borderwidth=1),
    ),
)

p1 = plot(
    [
        scatter(
            x=dates_uc,
            y=p_re_hyb[!, 2],
            name="Hybrid Sys. Renewable Dispatch",
            line_shape="hv",
            fill="tozeroy",
            line_color="cyan",
        ),
        scatter(
            x=dates_uc,
            y=p_re_param_hyb[!, 2],
            name="Hybrid Sys. Renewable Available",
            line_shape="hv",
            line=attr(color="royalblue"),
        ),
    ],
    Layout(
        yaxis_title="Power [x100 MW]",
        template="simply_white",
        legend=attr(x=0.6, y=1, font_size=14, bordercolor="Black", borderwidth=1),
    ),
)

cons = model.internal.container.constraints
for k in keys(cons)
    println(k)
end
aux = cons[PowerSimulations.ConstraintKey{
    HybridSystemsSimulations.EnergyAssetBalance,
    HybridSystem,
}(
    "",
)]
