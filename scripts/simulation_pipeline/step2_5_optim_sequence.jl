
###########################################
### Systems for DA and Merchant DA Bids ###
###########################################
sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys_noForecast")
sys_rts_merchant = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")

# There is no Wind + Thermal in a Single Bus.
# We will try to pick the Wind in 317 bus Chuhsi
# It does not have thermal and load, so we will pick the adjacent bus 318: Clark
bus_to_add = "Chuhsi" # "Barton"
add_da_forecast_in_5_mins_to_rt!(sys_rts_merchant, sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_da)
add_hybrid_to_chuhsi_bus!(sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_merchant)
add_hybrid_to_chuhsi_bus!(sys_rts_merchant)

interval_DA = Hour(24)
horizon_DA = 24
transform_single_time_series!(sys_rts_da, horizon_DA, interval_DA)
interval_RT = Hour(24)
horizon_RT = 24 * 12
transform_single_time_series!(sys_rts_merchant, horizon_RT, interval_RT)
horizon_merchant_rt = 24 * 12
horizon_merchant_da = 24
sys = sys_rts_merchant
sys.internal.ext = Dict{String, DataFrame}()
dic = PSY.get_ext(sys)

# Add prices to ext. Only three days.
bus_name = "chuhsi"
dic["λ_da_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic["horizon_RT"] = horizon_merchant_rt
dic["horizon_DA"] = horizon_merchant_da

hy_sys = first(get_components(HybridSystem, sys))
PSY.set_ext!(hy_sys, deepcopy(dic))

decision_optimizer_DA = DecisionModel(
    MerchantHybridEnergyCase,
    ProblemTemplate(CopperPlatePowerModel),
    sys,
    optimizer=Xpress.Optimizer,
    calculate_conflict=true,
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
bus_to_add = "Chuhsi" # "Barton"
sys_upd = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
sys_realized = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
horizon_merchant_rt = 12 * 24
horizon_merchant_da = 24
horizon_realized = 12 * 24
interval_merchant = Dates.Hour(24)
interval_realized = Dates.Hour(24)
#horizon_merchant_rt = 12
#interval_merchant = Dates.Hour(1)
#horizon_realized = 12
#interval_realized = Dates.Hour(1)

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
    "scripts/simulation_pipeline/inputs/$(bus_name)_DA_prices_updated_sim.csv",
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

#############

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
    sys_upd,
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
            sys_realized;
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
                source=ActivePowerOutVariable,
                affected_values=[EnergyDABidOut],
            ),
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=ActivePowerInVariable,
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
    steps=num_steps,
    models=models,
    sequence=sequence,
    initial_time=start_time,
    simulation_folder=mktempdir(cleanup=true),
)

build!(sim)

execute!(sim; enable_progress_bar=true)

# Check DA prices in Step 3 are same as here:
prices_uc_centralized = prices_uc_dcp
prices_uc_upd_stored = CSV.read(
    "scripts/simulation_pipeline/inputs/$(bus_name)_DA_prices_updated_sim.csv",
    DataFrame,
)[
    !,
    2,
]

results = SimulationResults(sim)
result_merch_DA = get_decision_problem_results(results, "MerchantHybridEnergyCase_DA")
results_merch_RT = get_decision_problem_results(results, "MerchantHybridEnergyCase_RT")
results_uc = get_decision_problem_results(results, "UC")
results_ed = get_decision_problem_results(results, "ED")

prices_uc_upd =
    read_realized_dual(results_uc, "CopperPlateBalanceConstraint__System")[!, 2] ./ 100.0

plot([
    scatter(
        x=dates_uc,
        y=prices_uc_centralized,
        name="Centralized DA Price",
        line_shape="hv",
    ),
    scatter(
        x=dates_uc,
        y=prices_uc_upd_stored,
        name="Stored DA Price after update",
        line_shape="hv",
    ),
    scatter(x=dates_uc, y=prices_uc_upd, name="Simulation DA Price", line_shape="hv"),
])

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

plot([
    scatter(
        x=dates_ed,
        y=prices_ed_centralized,
        name="Centralized RT Price",
        line_shape="hv",
    ),
    scatter(x=dates_ed, y=prices_ed_upd, name="Realized RT Price", line_shape="hv"),
])
