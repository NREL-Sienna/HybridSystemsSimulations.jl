include(joinpath(@__DIR__, "step1_prices.jl"))
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
transform_single_time_series!(sys_rts_da, horizon_DA, interval_DA)
transform_single_time_series!(sys_rts_merchant_da, horizon_DA * 12, interval_DA)
transform_single_time_series!(sys_rts_merchant_rt, horizon_RT, interval_RT)

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

for sys in [sys_rts_da, sys_rts_merchant_da, sys_rts_merchant_rt]
    services = get_components(VariableReserve, sys)
    hy_sys = first(get_components(HybridSystem, sys))
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
end

#########################################
########## Add Prices to EXT ############
#########################################
dic = PSY.get_ext(sys_rts_merchant_da)
bus_name = "chuhsi"
dic["λ_da_df"] =
    CSV.read("scripts/cooptimizer_pipeline/inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] =
    CSV.read("scripts/cooptimizer_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic["λ_Reg_Up"] =
    CSV.read("scripts/cooptimizer_pipeline/inputs/$(bus_name)_RegUp_prices.csv", DataFrame)
dic["λ_Reg_Down"] = CSV.read(
    "scripts/cooptimizer_pipeline/inputs/$(bus_name)_RegDown_prices.csv",
    DataFrame,
)
dic["λ_Spin_Up_R3"] =
    CSV.read("scripts/cooptimizer_pipeline/inputs/$(bus_name)_Spin_prices.csv", DataFrame)
dic["horizon_RT"] = horizon_RT
dic["horizon_DA"] = horizon_DA

sys_rts_merchant_da.internal.ext = deepcopy(dic)
sys_rts_merchant_da.internal.ext["horizon_RT"] = horizon_DA * 12
hy_sys_da = first(get_components(HybridSystem, sys_rts_merchant_da))
PSY.set_ext!(hy_sys_da, sys_rts_merchant_da.internal.ext)
sys_rts_merchant_rt.internal.ext = deepcopy(dic)
sys_rts_merchant_rt.internal.ext["horizon_DA"] = horizon_RT ÷ 12
hy_sys_rt = first(get_components(HybridSystem, sys_rts_merchant_rt))
PSY.set_ext!(hy_sys_rt, sys_rts_merchant_rt.internal.ext)

template_uc_copperplate = get_uc_copperplate_template(sys_rts_da)

decision_optimizer_DA = DecisionModel(
    MerchantHybridCooptimizerCase,
    template_uc_copperplate,
    sys_rts_merchant_da,
    optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => mipgap),
    calculate_conflict=true,
    optimizer_solve_log_print=false,
    system_to_file=false,
    store_variable_names=true;
    name="MerchantHybridCooptimizer_DA",
)

#=
build!(decision_optimizer_DA, output_dir = mktempdir())
solve!(decision_optimizer_DA)

res = ProblemResults(decision_optimizer_DA)
totbid_dn = res.aux_variable_values[PSI.AuxVarKey{HSS.TotalBidReserve, VariableReserve{ReserveDown}}("Reg_Down")]
regdn_out = res.variable_values[PSI.VariableKey{BidReserveVariableOut, VariableReserve{ReserveDown}}("Reg_Down")]
regdn_in = res.variable_values[PSI.VariableKey{BidReserveVariableIn, VariableReserve{ReserveDown}}("Reg_Down")]
=#

# Set Hybrid in UC as FixedDA
set_device_model!(
    template_uc_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridFixedDA;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)

set_service_model!(
    template_uc_copperplate,
    ServiceModel(VariableReserve{ReserveUp}, RangeReserve, use_slacks=false),
)
set_service_model!(
    template_uc_copperplate,
    ServiceModel(VariableReserve{ReserveDown}, RangeReserve, use_slacks=false),
)

######################################################
####### Systems for RT Bids and Realized ED ##########
######################################################
rt_template = ProblemTemplate(CopperPlatePowerModel)
set_device_model!(
    rt_template,
    DeviceModel(
        PSY.HybridSystem,
        HybridFixedDA;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)

decision_optimizer_RT = DecisionModel(
    MerchantHybridCooptimizerCase,
    rt_template,
    sys_rts_merchant_rt,
    system_to_file=false,
    optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => mipgap),
    calculate_conflict=true,
    store_variable_names=true;
    name="MerchantHybridCooptimizer_RT",
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
            calculate_conflict=true,
            direct_mode_optimizer=true,
            rebuild_model=false,
            store_variable_names=true,
            #check_numerical_bounds=false,
        ),
        decision_optimizer_RT,
    ],
)

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
            LowerBoundFeedforward(
                component_type=PSY.VariableReserve{ReserveUp},
                source=TotalBidReserve,
                affected_values=[ActivePowerReserveVariable],
            ),
            LowerBoundFeedforward(
                component_type=PSY.VariableReserve{ReserveDown},
                source=TotalBidReserve,
                affected_values=[ActivePowerReserveVariable],
            ),
        ],
        #=
        "MerchantHybridCooptimizer_RT" => [
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
            LowerBoundFeedforward(
                component_type=PSY.VariableReserve{ReserveUp},
                source=BidReserveVariableOut,
                affected_values=[BidReserveVariableOut],
            ),
            LowerBoundFeedforward(
                component_type=PSY.VariableReserve{ReserveDown},
                source=BidReserveVariableOut,
                affected_values=[BidReserveVariableOut],
            ),
            LowerBoundFeedforward(
                component_type=PSY.VariableReserve{ReserveUp},
                source=BidReserveVariableIn,
                affected_values=[BidReserveVariableIn],
            ),
            LowerBoundFeedforward(
                component_type=PSY.VariableReserve{ReserveDown},
                source=BidReserveVariableIn,
                affected_values=[BidReserveVariableIn],
            ),
        ],
        =#
    ),
    ini_cond_chronology=InterProblemChronology(),
)

sim_steps = 3 # num_steps - 2
sim = Simulation(
    name="compact_sim",
    steps=sim_steps,
    models=models,
    sequence=sequence,
    initial_time=starttime,
    simulation_folder=mktempdir(cleanup=true),
)

build!(sim)

execute!(sim; enable_progress_bar=true)

#=
ucmod = sim.models.decision_models[2]
vars = ucmod.internal.container.variables
cons = ucmod.internal.container.constraints
regdn_var = vars[PSI.VariableKey{ActivePowerReserveVariable, VariableReserve{ReserveDown}}("Reg_Down")]
regdn_con = cons[PSI.ConstraintKey{RequirementConstraint, VariableReserve{ReserveDown}}("Reg_Down")]
=#
### Process Results

results = SimulationResults(sim)
result_merch_DA = get_decision_problem_results(results, "MerchantHybridCooptimizer_DA")
result_merch_RT = get_decision_problem_results(results, "MerchantHybridCooptimizer_RT")
results_uc = get_decision_problem_results(results, "UC")

## Prices Comparison
prices_uc_centralized = prices_uc_dcp
prices_ed_centralized = prices_ed_dcp
prices_uc_upd =
    read_realized_dual(results_uc, "CopperPlateBalanceConstraint__System")[!, 2] ./ 100.0

uc_out = read_realized_variable(results_uc, "ActivePowerOutVariable__HybridSystem")
uc_in = read_realized_variable(results_uc, "ActivePowerOutVariable__HybridSystem")

plot(
    [
        scatter(
            x=dates_uc[1:(24 * sim_steps)],
            y=prices_uc_centralized[1:(24 * sim_steps)],
            name="Centralized DA Price",
            line_shape="hv",
        ),
        scatter(x=dates_uc, y=prices_uc_upd, name="Simulation DA Price", line_shape="hv"),
    ],
    Layout(title="Price Differences", yaxis_title="\$/MWh"),
)

### Bid Comparison

da_out = read_variable(result_merch_DA, "EnergyDABidOut__HybridSystem")
da_out_realized = vcat([values(vdf)[!, 2][1:24] for vdf in values(da_out)]...)
da_in = read_variable(result_merch_DA, "EnergyDABidIn__HybridSystem")
da_in_realized = vcat([values(vdf)[!, 2][1:24] for vdf in values(da_in)]...)

uc_p_out = read_realized_variable(results_uc, "ActivePowerOutVariable__HybridSystem")
uc_p_in = read_realized_variable(results_uc, "ActivePowerInVariable__HybridSystem")

da_out_rt = read_variable(result_merch_RT, "EnergyDABidOut__HybridSystem")
da_out_rt_realized = vcat([values(vdf)[!, 2][1] for vdf in values(da_out_rt)]...)
da_in_rt = read_variable(result_merch_RT, "EnergyDABidIn__HybridSystem")
da_in_rt_realized = vcat([values(vdf)[!, 2][1] for vdf in values(da_in_rt)]...)

p1 = plot([
    scatter(x=dates_uc, y=da_out_realized, name="DA Bid Out", line_shape="hv"),
    scatter(x=dates_uc, y=da_in_realized, name="DA Bid In", line_shape="hv"),
    scatter(x=uc_p_out[!, 1], y=uc_p_out[!, 2] / 100.0, name="UC P Out", line_shape="hv"),
    scatter(x=uc_p_in[!, 1], y=uc_p_in[!, 2] / 100.0, name="UC P In", line_shape="hv"),
    scatter(x=dates_uc, y=da_out_rt_realized, name="DA Bid Out RT", line_shape="hv"),
    scatter(x=dates_uc, y=da_in_rt_realized, name="DA Bid In RT", line_shape="hv"),
])

regup_da_out = read_variable(
    result_merch_DA,
    "BidReserveVariableOut__VariableReserve__ReserveUp__Reg_Up",
)
regup_da_out_realized = vcat([values(vdf)[!, 2][1:24] for vdf in values(regup_da_out)]...)

regup_da_in = read_variable(
    result_merch_DA,
    "BidReserveVariableIn__VariableReserve__ReserveUp__Reg_Up",
)
regup_da_in_realized = vcat([values(vdf)[!, 2][1:24] for vdf in values(regup_da_in)]...)

regup_uc_out = read_realized_variable(
    results_uc,
    "ReserveVariableOut__VariableReserve__ReserveUp__Reg_Up",
)
regup_uc_in = read_realized_variable(
    results_uc,
    "ReserveVariableIn__VariableReserve__ReserveUp__Reg_Up",
)

p2 = plot([
    scatter(x=dates_uc, y=regup_da_out_realized, name="RegUp DA Bid Out", line_shape="hv"),
    scatter(x=dates_uc, y=regup_da_in_realized, name="RegUp DA Bid In", line_shape="hv"),
    scatter(
        x=regup_uc_out[!, 1],
        y=regup_uc_out[!, 2],
        name="UC RegUp Out",
        line_shape="hv",
    ),
    scatter(x=regup_uc_in[!, 1], y=regup_uc_in[!, 2], name="UC RegUp In", line_shape="hv"),
])
