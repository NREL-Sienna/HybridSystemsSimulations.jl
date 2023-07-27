bus_to_add = "Chuhsi" # "Barton"
sys_upd = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
sys_realized = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
horizon_merchant_rt = 12 * 24
horizon_realized = 12 * 24
interval_merchant = Dates.Hour(24)
interval_realized = Dates.Hour(24)

for sys in [sys_upd, sys_realized]
    bus_to_add = "Chuhsi" # "Barton"
    modify_ren_curtailment_cost!(sys)
    add_hybrid_to_chuhsi_bus!(sys)
    #for l in get_components(PowerLoad, sys)
    #    set_max_active_power!(l, get_max_active_power(l) * 1.3)
    #end
end

transform_single_time_series!(sys_upd, horizon_merchant_rt, interval_merchant)
transform_single_time_series!(sys_realized, horizon_realized, interval_realized)

sys_upd.internal.ext = Dict{String, DataFrame}()
dic_upd = PSY.get_ext(sys_upd)

bus_name = "chuhsi"
dic_upd["λ_da_df"] = CSV.read(
    "scripts/simulation_pipeline/inputs/$(bus_name)_DA_prices_updated.csv",
    DataFrame,
)
dic_upd["λ_rt_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic_upd["bid_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_bid_fixed.csv", DataFrame)
dic_upd["horizon_RT"] = horizon_merchant_rt
dic_upd["horizon_DA"] = horizon_merchant_da

hy_sys = first(get_components(HybridSystem, sys_upd))
PSY.set_ext!(hy_sys, deepcopy(dic_upd))

m_upd = DecisionModel(
    MerchantHybridEnergyFixedDA,
    ProblemTemplate(CopperPlatePowerModel),
    sys_upd,
    optimizer=Xpress.Optimizer,
    store_variable_names=true,
    system_to_file=false,
)

template_ed_copperplate = get_ed_copperplate_template_noslack(sys_realized)
set_device_model!(
    template_ed_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridEnergyOnlyFixedDA;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)
set_device_model!(
    template_ed_copperplate,
    DeviceModel(
        PSY.ThermalStandard,
        ThermalDispatchNoMin,
    ),
)

mipgap = 0.005
num_steps = 3
starttime = DateTime("2020-10-03T00:00:00")

models = SimulationModels(
    decision_models=[
        m_upd,
        DecisionModel(
            template_ed_copperplate,
            sys_realized;
            name="Realized",
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

sequence = SimulationSequence(
    models=models,
    feedforwards=Dict(
        "Realized" => [
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=ActivePowerOutVariable,
                affected_values=[ActivePowerOutVariable],
            ),
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=ActivePowerInVariable,
                affected_values=[ActivePowerInVariable],
            ),
        ],
    ),
    ini_cond_chronology=InterProblemChronology(),
)

sim = Simulation(
    name="compact_sim",
    steps=num_steps,
    models=models,
    sequence=sequence,
    initial_time=start_time,
    simulation_folder=mktempdir(cleanup=true),
)

build!(sim)
execute!(sim; enable_progress_bar=true)


results = SimulationResults(sim)
result_merchant = get_decision_problem_results(results, "MerchantHybridEnergyFixedDA")
result_realized = get_decision_problem_results(results, "Realized")

da_bid_out_dic = read_variable(result_merchant, "EnergyDABidOut__HybridSystem")
full_horizon = 72
da_bid_out_realized = zeros(full_horizon)
da_horizon = 24
i = 0
for (k, bid) in da_bid_out_dic
    da_bid_out_realized[(da_horizon * i + 1):((i + 1) * da_horizon)] = bid[!, 1]
    i = i + 1
end

da_bid_in_dic = read_variable(result_merchant, "EnergyDABidIn__HybridSystem")
da_bid_in_realized = zeros(full_horizon)
i = 0
for (k, bid) in da_bid_in_dic
    da_bid_in_realized[(da_horizon * i + 1):((i + 1) * da_horizon)] = bid[!, 1]
    i = i + 1
end

p_out_upd = read_realized_variable(result_merchant, "ActivePowerOutVariable__HybridSystem")[!, 2]
p_in_upd = read_realized_variable(result_merchant, "ActivePowerInVariable__HybridSystem")[!, 2]

p_out_realized = read_realized_variable(result_realized, "ActivePowerOutVariable__HybridSystem")[!, 2]
p_in_realized = read_realized_variable(result_realized, "ActivePowerInVariable__HybridSystem")[!, 2]

p_ch_upd = read_realized_variable(result_merchant, "BatteryCharge__HybridSystem")[!, 2]
p_ds_upd = read_realized_variable(result_merchant, "BatteryDischarge__HybridSystem")[!, 2]

p_re_upd = read_realized_variable(result_merchant, "RenewablePower__HybridSystem")[!, 2]

plot([
    scatter(x = dates_ed, y = p_out_upd, name = "Merchant POut")
    scatter(x = dates_ed, y = p_out_realized, name = "Realized POut")
])

prices_ed_realized =
    read_realized_dual(results_realized, "CopperPlateBalanceConstraint__System")[!, 2] ./
    100.0 * 60 / 5

