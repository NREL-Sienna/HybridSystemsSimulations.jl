include(
    "/Users/jlara/cache/HybridSystemsSimulations.jl/scripts/simulation_pipeline/step1_prices.jl",
)
###########################################
### Systems for DA and Merchant DA Bids ###
###########################################
sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys_noForecast")
sys_rts_merchant_da = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
sys_rts_merchant_rt = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")

# There is no Wind + Thermal in a Single Bus.
# We will try to pick the Wind in 317 bus Chuhsi
# It does not have thermal and load, so we will pick the adjacent bus 318: Clark
bus_to_add = "Chuhsi" # "Barton"
add_da_forecast_in_5_mins_to_rt!(sys_rts_merchant_da, sys_rts_da)
add_da_forecast_in_5_mins_to_rt!(sys_rts_merchant_rt, sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_da)
add_hybrid_to_chuhsi_bus!(sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_merchant_da)
modify_ren_curtailment_cost!(sys_rts_merchant_rt)
add_hybrid_to_chuhsi_bus!(sys_rts_merchant_da)
add_hybrid_to_chuhsi_bus!(sys_rts_merchant_rt)

interval_DA = Hour(24)
horizon_DA = 24
transform_single_time_series!(sys_rts_da, horizon_DA, interval_DA)
interval_RT = Hour(1)
horizon_RT = 24
transform_single_time_series!(sys_rts_merchant_da, horizon_DA * 12, interval_DA)
transform_single_time_series!(sys_rts_merchant_rt, horizon_RT, interval_RT)

dic = PSY.get_ext(sys_rts_merchant_da)

# Add prices to ext. Only three days.
bus_name = "chuhsi"
dic["λ_da_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic["horizon_RT"] = horizon_RT
dic["horizon_DA"] = horizon_DA

sys_rts_merchant_da.internal.ext = deepcopy(dic)
sys_rts_merchant_da.internal.ext["horizon_RT"] = horizon_DA * 12
hy_sys_da = first(get_components(HybridSystem, sys_rts_merchant_da))
PSY.set_ext!(hy_sys_da, sys_rts_merchant_da.internal.ext)
sys_rts_merchant_rt.internal.ext = deepcopy(dic)
sys_rts_merchant_rt.internal.ext["horizon_DA"] = 1
hy_sys_rt = first(get_components(HybridSystem, sys_rts_merchant_rt))
PSY.set_ext!(hy_sys_rt, sys_rts_merchant_rt.internal.ext)

decision_optimizer_DA = DecisionModel(
    MerchantHybridEnergyCase,
    ProblemTemplate(CopperPlatePowerModel),
    sys_rts_merchant_da,
    optimizer=Xpress.Optimizer,
    calculate_conflict=true,
    system_to_file=false,
    store_variable_names=true;
    name="MerchantHybridEnergyCase_DA",
)

template_uc_copperplate = get_uc_copperplate_template(sys_rts_da)
# Set Hybrid in UC as FixedDA
set_device_model!(
    template_uc_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridEnergyOnlyFixedDA;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)
######################################################
####### Systems for RT Bids and Realized ED ##########
######################################################
rt_template = ProblemTemplate(CopperPlatePowerModel)
set_device_model!(
    rt_template,
    DeviceModel(
        PSY.HybridSystem,
        HybridEnergyOnlyFixedDA;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)

decision_optimizer_RT = DecisionModel(
    MerchantHybridEnergyCase,
    rt_template,
    sys_rts_merchant_rt,
    system_to_file=false,
    optimizer=Xpress.Optimizer,
    calculate_conflict=true,
    store_variable_names=true;
    name="MerchantHybridEnergyCase_RT",
)

decision_optimizer_RT.ext = Dict{String, Any}("RT" => true)

# Construct decision models for simulation
models = SimulationModels(
    decision_models=[
        decision_optimizer_DA,
        DecisionModel(
            template_uc_copperplate,
            sys_rts_da;
            name="UC",
            optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => mipgap),
            system_to_file=false,
            initialize_model=true,
            optimizer_solve_log_print=false,
            direct_mode_optimizer=true,
            rebuild_model=false,
            store_variable_names=true,
            #check_numerical_bounds=false,
        ),
        decision_optimizer_RT,
        DecisionModel(
            template_ed_copperplate,
            sys_rts_merchant_rt;
            name="ED",
            optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => mipgap),
            system_to_file=false,
            initialize_model=true,
            optimizer_solve_log_print=false,
            direct_mode_optimizer=true,
            rebuild_model=false,
            store_variable_names=true,
            #check_numerical_bounds=false,
        ),
    ],
)

# Set-up the sequence Optimizer-UC
sequence = SimulationSequence(
    models=models,
    feedforwards=Dict(
        "UC" => [
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyDABidOut,
                affected_values=[ActivePowerOutVariable],
            ),
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyDABidIn,
                affected_values=[ActivePowerInVariable],
            ),
        ],
        "MerchantHybridEnergyCase_RT" => [
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyDABidOut,
                affected_values=[EnergyDABidOut],
            ),
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyDABidIn,
                affected_values=[EnergyDABidIn],
            ),
        ],
        "ED" => [
            SemiContinuousFeedforward(
                component_type=ThermalStandard,
                source=OnVariable,
                affected_values=[ActivePowerVariable],
            ),
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyRTBidOut,
                affected_values=[ActivePowerOutVariable],
            ),
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyRTBidIn,
                affected_values=[ActivePowerInVariable],
            ),
        ],
    ),
    ini_cond_chronology=InterProblemChronology(),
)

sim = Simulation(
    name="compact_sim",
    steps=num_steps - 1,
    models=models,
    sequence=sequence,
    initial_time=starttime,
    simulation_folder=mktempdir(cleanup=true),
)

build!(sim)

execute!(sim; enable_progress_bar=true)

results = SimulationResults(sim)
result_merch_DA = get_decision_problem_results(results, "MerchantHybridEnergyCase_DA")
result_merch_RT = get_decision_problem_results(results, "MerchantHybridEnergyCase_RT")
results_uc = get_decision_problem_results(results, "UC")
results_ed = get_decision_problem_results(results, "ED")

# Check DA prices in Step 3 are same as here:
prices_uc_centralized = prices_uc_dcp
prices_uc_upd =
    read_realized_dual(results_uc, "CopperPlateBalanceConstraint__System")[!, 2] ./ 100.0

uc_out = read_realized_variable(results_uc, "ActivePowerOutVariable__HybridSystem")
uc_in = read_realized_variable(results_uc, "ActivePowerOutVariable__HybridSystem")

plot(
    [
        scatter(
            x=dates_uc[1:(24 * 5)],
            y=prices_uc_centralized[1:(24 * 5)],
            name="Centralized DA Price",
            line_shape="hv",
        ),
        scatter(x=dates_uc, y=prices_uc_upd, name="Simulation DA Price", line_shape="hv"),
    ],
    Layout(title="Price Differences", yaxis_title="\$/MWh"),
)

tmap = get_ext(hy_sys_da)["tmap"]
DART = [λ_da[tmap[t]] - λ_rt[t] for t in 1:horizon_merchant_rt]
# Store Prices from Simulation #
#=
DA_prices_upd = DataFrame()
DA_prices_upd[!, "DateTime"] = dates_uc
DA_prices_upd[!, "Chuhsi"] = prices_uc_upd
CSV.write("scripts/simulation_pipeline/inputs/chuhsi_DA_prices_updated_sim.csv", DA_prices_upd)
=#

# Compare Prices in RT
prices_ed_centralized = prices_ed_dcp
prices_ed_upd =
    read_realized_dual(results_ed, "CopperPlateBalanceConstraint__System")[!, 2] ./ 100.0 *
    60 / 5

plot(
    [
        scatter(
            x=dates_ed[1:(24 * 5 * 12)],
            y=prices_ed_centralized[1:(24 * 5 * 12)],
            name="Centralized RT Price",
            line_shape="hv",
        ),
        scatter(x=dates_ed, y=prices_ed_upd, name="Realized RT Price", line_shape="hv"),
    ],
    Layout(title="Price Differences", yaxis_title="\$/MWh"),
)

plot([
    scatter(
        x=dates_ed[1:(24 * 5 * 12)],
        y=prices_ed_centralized[1:(24 * 5 * 12)],
        name="Centralized RT Price",
        line_shape="hv",
    ),
    scatter(x=dates_ed, y=prices_ed_upd, name="Realized RT Price", line_shape="hv"),
])

da_rt_forecast_out = read_realized_variable(result_merch_DA, "EnergyRTBidOut__HybridSystem")
da_rt_forecast_in = read_realized_variable(result_merch_DA, "EnergyRTBidIn__HybridSystem")

rt_out = read_realized_variable(result_merch_RT, "EnergyRTBidOut__HybridSystem")
rt_in = read_realized_variable(result_merch_RT, "EnergyRTBidIn__HybridSystem")

da_out = read_variable(result_merch_DA, "EnergyDABidOut__HybridSystem")
da_in = read_variable(result_merch_DA, "EnergyDABidIn__HybridSystem")

da_out_rt = read_variable(result_merch_RT, "EnergyDABidOut__HybridSystem")
da_in_rt = read_variable(result_merch_RT, "EnergyDABidIn__HybridSystem")

uc_p_out = read_realized_variable(results_uc, "ActivePowerOutVariable__HybridSystem")
uc_p_in = read_realized_variable(results_uc, "ActivePowerInVariable__HybridSystem")

p1 = plot([
    scatter(
        x=dates_uc,
        y=vcat(values(da_out)...)[!, 1],
        name="DA Bid Out",
        line_shape="hv",
    ),
    scatter(x=dates_uc, y=vcat(values(da_in)...)[!, 1], name="DA Bid In", line_shape="hv"),
    scatter(x=uc_p_out[!, 1], y=uc_p_out[!, 2] / 100.0, name="UC P Out", line_shape="hv"),
    scatter(x=uc_p_in[!, 1], y=uc_p_in[!, 2] / 100.0, name="UC P In", line_shape="hv"),
    scatter(
        x=dates_uc,
        y=vcat(values(da_out_rt)...)[!, 1],
        name="DA Bid Out RT",
        line_shape="hv",
    ),
    scatter(
        x=dates_uc,
        y=vcat(values(da_in_rt)...)[!, 1],
        name="DA Bid In RT",
        line_shape="hv",
    ),
])

p1 = plot([
    scatter(
        x=da_rt_forecast_out[!, "DateTime"],
        y=da_rt_forecast_out[!, 2],
        name="DA RT Bid Out",
        line_shape="hv",
    ),
    scatter(
        x=rt_out[!, "DateTime"],
        y=rt_out[!, 2],
        name="Realized RT Bid Out",
        line_shape="hv",
    ),
])

p2 = plot([
    scatter(
        x=da_rt_forecast_in[!, "DateTime"],
        y=da_rt_forecast_in[!, 2],
        name="DA RT Bid In",
        line_shape="hv",
    ),
    scatter(
        x=rt_in[!, "DateTime"],
        y=rt_in[!, 2],
        name="Realized RT Bid In",
        line_shape="hv",
    ),
])

[p1; p2]

da_rt_forecast_discharge =
    read_realized_variable(result_merch_DA, "BatteryDischarge__HybridSystem")
da_rt_forecast_charge =
    read_realized_variable(result_merch_DA, "BatteryCharge__HybridSystem")
da_rt_forecast_re = read_realized_variable(result_merch_DA, "RenewablePower__HybridSystem")
da_rt_forecast_th = read_realized_variable(result_merch_DA, "ThermalPower__HybridSystem")
da_rt_forecast_re_available =
    read_realized_parameter(result_merch_DA, "RenewablePowerTimeSeries__HybridSystem")
da_rt_soc = read_realized_variable(result_merch_DA, "EnergyVariable__HybridSystem")

rt_forecast_discharge =
    read_realized_variable(result_merch_RT, "BatteryDischarge__HybridSystem")
rt_forecast_charge = read_realized_variable(result_merch_RT, "BatteryCharge__HybridSystem")
rt_forecast_th = read_realized_variable(result_merch_RT, "ThermalPower__HybridSystem")
rt_forecast_re = read_realized_variable(result_merch_RT, "RenewablePower__HybridSystem")
rt_forecast_re_available =
    read_realized_parameter(result_merch_RT, "RenewablePowerTimeSeries__HybridSystem")
rt_soc = read_realized_variable(result_merch_RT, "EnergyVariable__HybridSystem")

p1 = plot([
    scatter(
        x=dates_ed[1:(24 * 5 * 12)],
        y=prices_ed_centralized[1:(24 * 5 * 12)],
        name="Centralized RT Price",
        line_shape="hv",
    ),
    scatter(
        x=da_rt_forecast_out[!, "DateTime"],
        y=da_rt_forecast_out[!, 2],
        name="DA RT Bid Out",
        line_shape="hv",
    ),
    scatter(
        x=da_rt_forecast_in[!, "DateTime"],
        y=-1 * da_rt_forecast_in[!, 2],
        name="DA RT Bid In",
        line_shape="hv",
    ),
    scatter(
        x=da_rt_soc[!, "DateTime"],
        y=da_rt_soc[!, 2] / 100.0,
        name="DA SoC",
        line_shape="hv",
    ),
    scatter(
        x=da_rt_forecast_re_available[!, "DateTime"],
        y=da_rt_forecast_re_available[!, 2],
        name="RE Available",
        line_shape="hv",
    ),
    scatter(
        x=da_rt_forecast_discharge[!, "DateTime"],
        y=da_rt_forecast_discharge[!, 2],
        name="DA Discharge",
        line_shape="hv",
        mode="none",
        stackgroup="two",
    ),
    scatter(
        x=da_rt_forecast_charge[!, "DateTime"],
        y=-1da_rt_forecast_charge[!, 2],
        name="DA Charge",
        line_shape="hv",
        mode="none",
        stackgroup="two",
    ),
    scatter(
        x=da_rt_forecast_th[!, "DateTime"],
        y=da_rt_forecast_th[!, 2],
        name="DA Thermal",
        line_shape="hv",
        mode="none",
        stackgroup="two",
    ),
    scatter(
        x=da_rt_forecast_re[!, "DateTime"],
        y=da_rt_forecast_re[!, 2],
        name="DA RE",
        line_shape="hv",
        mode="none",
        stackgroup="two",
    ),
])

p1 = plot([
    scatter(
        x=dates_ed[1:(24 * 5 * 12)],
        y=prices_ed_centralized[1:(24 * 5 * 12)],
        name="Centralized RT Price",
        line_shape="hv",
    ),
    scatter(x=da_out[!, 1], y=da_out[!, 2], name="DA Bid Out", line_shape="hv"),
    scatter(x=da_in[!, 1], y=da_in[!, 2], name="DA Bid In", line_shape="hv"),
    scatter(x=rt_out[!, "DateTime"], y=rt_out[!, 2], name="RT Bid Out", line_shape="hv"),
    scatter(x=rt_in[!, "DateTime"], y=-1 * rt_in[!, 2], name="RT Bid In", line_shape="hv"),
    scatter(
        x=rt_soc[!, "DateTime"],
        y=rt_soc[!, 2] / 100.0,
        name="RT SoC",
        line_shape="hv",
    ),
    scatter(
        x=rt_forecast_re_available[!, "DateTime"],
        y=rt_forecast_re_available[!, 2],
        name="RE Available",
        line_shape="hv",
    ),
    scatter(
        x=rt_forecast_discharge[!, "DateTime"],
        y=rt_forecast_discharge[!, 2],
        name="RT Discharge",
        line_shape="hv",
        mode="none",
        stackgroup="two",
    ),
    scatter(
        x=rt_forecast_charge[!, "DateTime"],
        y=-1 * rt_forecast_charge[!, 2],
        name="RT Charge",
        line_shape="hv",
        mode="none",
        stackgroup="two",
    ),
    scatter(
        x=rt_forecast_th[!, "DateTime"],
        y=rt_forecast_th[!, 2],
        name="RT Thermal",
        line_shape="hv",
        mode="none",
        stackgroup="two",
    ),
    scatter(
        x=rt_forecast_re[!, "DateTime"],
        y=rt_forecast_re[!, 2],
        name="RT RE",
        line_shape="hv",
        mode="none",
        stackgroup="two",
    ),
])
