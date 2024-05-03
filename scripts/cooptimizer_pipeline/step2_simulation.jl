include(joinpath(@__DIR__, "step1_prices.jl"))
###########################################
### Systems for DA and Merchant DA Bids ###
###########################################
# JuMP._TERM_LIMIT_FOR_PRINTING[] = 10000
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

set_device_model!(
    template_uc_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridDispatchWithReserves;
        #HybridEnergyOnlyDispatch;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "storage_reservation" => true,
            "energy_target" => true,
            "cycling" => true,
            "regularization" => true,
        ),
    ),
)

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
#build!(decision_optimizer_DA, output_dir = mktempdir())
#=
build!(decision_optimizer_DA, output_dir = mktempdir())
solve!(decision_optimizer_DA)

res = ProblemResults(decision_optimizer_DA)
totbid_dn = res.aux_variable_values[PSI.AuxVarKey{HSS.TotalBidReserve, VariableReserve{ReserveDown}}("Reg_Down")]
regdn_out = res.variable_values[PSI.VariableKey{BidReserveVariableOut, VariableReserve{ReserveDown}}("Reg_Down")]
regdn_in = res.variable_values[PSI.VariableKey{BidReserveVariableIn, VariableReserve{ReserveDown}}("Reg_Down")]

exprs = decision_optimizer_DA.internal.container.expressions
for k in keys(exprs)
    println(k)
end

exprs[PowerSimulations.ExpressionKey{HybridSystemsSimulations.DischargeServedReserveDownExpression, HybridSystem}("")]

=#

# Set Hybrid in UC as FixedDA
template_uc_copperplate_UC = deepcopy(template_uc_copperplate)

set_device_model!(
    template_uc_copperplate_UC,
    DeviceModel(
        PSY.HybridSystem,
        HybridFixedDA;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)

set_service_model!(
    template_uc_copperplate_UC,
    ServiceModel(VariableReserve{ReserveUp}, RangeReserve, use_slacks=false),
)
set_service_model!(
    template_uc_copperplate_UC,
    ServiceModel(VariableReserve{ReserveDown}, RangeReserve, use_slacks=false),
)

template_ed_copperplate = deepcopy(template_uc_copperplate_UC)
set_device_model!(template_ed_copperplate, ThermalStandard, ThermalBasicDispatch)
set_device_model!(template_ed_copperplate, HydroDispatch, FixedOutput)
#set_device_model!(template_ed, HydroEnergyReservoir, FixedOutput)
for s in values(template_ed_copperplate.services)
    s.use_slacks = true
end

######################################################
####### Systems for RT Bids and Realized ED ##########
######################################################
rt_template = ProblemTemplate(CopperPlatePowerModel)

set_device_model!(
    rt_template,
    DeviceModel(
        PSY.HybridSystem,
        HybridDispatchWithReserves;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "storage_reservation" => true,
            "energy_target" => true,
            "cycling" => false,
            "regularization" => true,
        ),
    ),
)

set_service_model!(rt_template, ServiceModel(VariableReserve{ReserveUp}, RangeReserve))
set_service_model!(rt_template, ServiceModel(VariableReserve{ReserveDown}, RangeReserve))

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

decision_optimizer_RT.ext = Dict{String, Any}("RT" => false)

# Construct decision models for simulation
models = SimulationModels(
    decision_models=[
        decision_optimizer_DA,
        DecisionModel(
            template_uc_copperplate_UC,
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
            #FixValueFeedforward(
            #    component_type=component_type = HybridSystem,
            #    source=TotalReserve,
            #    affected_values=[TotalReserve],
            #),
        ],
        # This FF configuration allows the Hybrid to re-assign reserves internally
        # But it can't increase the reserve offer to the ED
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
            CyclingChargeLimitFeedforward(
                component_type=PSY.HybridSystem,
                source=HSS.CumulativeCyclingCharge,
                affected_values=[HSS.CyclingChargeLimitParameter],
                target_period=1,
                penalty_cost=0.0,
            ),
            CyclingDischargeLimitFeedforward(
                component_type=PSY.HybridSystem,
                source=HSS.CumulativeCyclingDischarge,
                affected_values=[HSS.CyclingDischargeLimitParameter],
                target_period=1,
                penalty_cost=0.0,
            ),
            #FixValueFeedforward(
            #    component_type=PSY.HybridSystem,
            #    source=TotalReserve,
            #    affected_values=[TotalReserve],
            #),

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
            LowerBoundFeedforward(
                component_type=PSY.VariableReserve{ReserveUp},
                source=ActivePowerReserveVariable,
                affected_values=[ActivePowerReserveVariable],
                add_slacks=true,
            ),
            LowerBoundFeedforward(
                component_type=PSY.VariableReserve{ReserveDown},
                source=ActivePowerReserveVariable,
                affected_values=[ActivePowerReserveVariable],
                add_slacks=true,
            ),
            #FixValueFeedforward(
            #    component_type=HybridSystem,
            #    source=TotalReserve,
            #    affected_values=[TotalReserve],
            #),
        ],
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
#da_merch = sim.models.decision_models[1]
#ucmod = sim.models.decision_models[2]
#rt_merch = sim.models.decision_models[3]
#edmod = sim.models.decision_models[4]

#params = rt_merch.internal.container.parameters
#tot_reserve_param =
#    params[PSI.ParameterKey{FixValueParameter, HybridSystem}("TotalReserve")]
#tot_reserve_param[:, :, 6]
#vars = rt_merch.internal.container.variables
#totres = vars[PSI.VariableKey{TotalReserve, HybridSystem}("")];
#JuMP.lower_bound(totres["317_Hybrid", "Reg_Up", 1])

#for (k, v) in rt_merch.internal.container.variables
#    @show k
#    for v_ in v
#        if v_.index.value == 110
#            @show v_
#        end
#    end
#end

cons = rt_merch.internal.container.constraints
cons[PSI.ConstraintKey{HSS.HybridReserveAssignmentConstraint, HybridSystem}("")]
tot_reserve = vars[PSI.VariableKey{TotalReserve, HybridSystem}("")]
regdn_var = vars[PSI.VariableKey{ActivePowerReserveVariable, VariableReserve{ReserveDown}}(
    "Reg_Down",
)]
regdn_con =
    cons[PSI.ConstraintKey{RequirementConstraint, VariableReserve{ReserveDown}}("Reg_Down")]
=#

### Process Results

results = SimulationResults(sim)
result_merch_DA = get_decision_problem_results(results, "MerchantHybridCooptimizer_DA")
result_merch_RT = get_decision_problem_results(results, "MerchantHybridCooptimizer_RT")
results_uc = get_decision_problem_results(results, "UC")
results_ed = get_decision_problem_results(results, "ED")

p_soc_da = read_realized_variable(result_merch_DA, "EnergyVariable__HybridSystem")
p_soc_rt = read_realized_variable(result_merch_RT, "EnergyVariable__HybridSystem")

#p_tot_reserve = read_variable(result_merch_DA, "TotalReserve__HybridSystem")

day = DateTime("2020-10-03T00:00:00")

aux_var_cycling =
    read_aux_variable(result_merch_DA, "CumulativeCyclingCharge__HybridSystem")
first_day_aux_var = aux_var_cycling[day]

charge_var = read_variable(result_merch_DA, "BatteryCharge__HybridSystem")
first_day_charge = charge_var[day]
dates = first_day_charge[!, 1]

reg_up_charge_var = read_variable(
    result_merch_DA,
    "ChargingReserveVariable__VariableReserve__ReserveUp__Reg_Up",
)
first_day_regup_charge = reg_up_charge_var[day]

reg_dn_charge_var = read_variable(
    result_merch_DA,
    "ChargingReserveVariable__VariableReserve__ReserveDown__Reg_Down",
)
first_day_regdn_charge = reg_dn_charge_var[day]

dev_cumulative = similar(first_day_charge[!, 2])

efficiency = hy_sys_da.storage.efficiency
fraction_of_hour = 1 / 12

for ix in 1:length(dev_cumulative)
    dev_cumulative[ix] =
        efficiency.in *
        fraction_of_hour *
        sum(
            first_day_charge[!, 2][k] + 0.3 * first_day_regdn_charge[!, 2][k] -
            0.3 * first_day_regup_charge[!, 2][k] for k in 1:ix
        )
end

plot([
    scatter(x=dates, y=first_day_charge[!, 2], name="Charge Var"),
    scatter(x=dates, y=first_day_aux_var[!, 2], name="Cumulative Aux Var Cycling"),
    scatter(x=dates, y=first_day_regup_charge[!, 2], name="Reg Up Charge"),
    scatter(x=dates, y=first_day_regdn_charge[!, 2], name="Reg Dn Charge"),
    scatter(
        x=dates,
        y=first_day_charge[!, 2] + 0.3 * first_day_regdn_charge[!, 2] -
          0.3 * first_day_regup_charge[!, 2],
        name="Effective Charge Var",
    ),
])

plot(p_soc_da[!, 2])

par = read_parameter(result_merch_DA, "CyclingDischargeLimitParameter__HybridSystem")

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
da_out_realized = vcat([values(vdf)[!, 1][1:24] for vdf in values(da_out)]...)
da_in = read_variable(result_merch_DA, "EnergyDABidIn__HybridSystem")
da_in_realized = vcat([values(vdf)[!, 1][1:24] for vdf in values(da_in)]...)

uc_p_out = read_realized_variable(results_uc, "ActivePowerOutVariable__HybridSystem")
uc_p_in = read_realized_variable(results_uc, "ActivePowerInVariable__HybridSystem")

da_out_rt = read_variable(result_merch_RT, "EnergyDABidOut__HybridSystem")
da_out_rt_realized = vcat([values(vdf)[!, 1][1] for vdf in values(da_out_rt)]...)
da_in_rt = read_variable(result_merch_RT, "EnergyDABidIn__HybridSystem")
da_in_rt_realized = vcat([values(vdf)[!, 1][1] for vdf in values(da_in_rt)]...)

ed_p_out = read_realized_variable(results_ed, "ActivePowerOutVariable__HybridSystem")
ed_p_in = read_realized_variable(results_ed, "ActivePowerInVariable__HybridSystem")

p1 = plot([
    scatter(x=dates_uc, y=da_out_realized, name="DA Bid Out", line_shape="hv"),
    scatter(x=dates_uc, y=da_in_realized, name="DA Bid In", line_shape="hv"),
    scatter(x=uc_p_out[!, 1], y=uc_p_out[!, 2] / 100.0, name="UC P Out", line_shape="hv"),
    scatter(x=uc_p_in[!, 1], y=uc_p_in[!, 2] / 100.0, name="UC P In", line_shape="hv"),
    scatter(x=dates_uc, y=da_out_rt_realized, name="DA Bid Out RT", line_shape="hv"),
    scatter(x=dates_uc, y=da_in_rt_realized, name="DA Bid In RT", line_shape="hv"),
    scatter(x=dates_ed, y=ed_p_out[!, 2] / 100.0, name="ED P Out", line_shape="hv"),
    scatter(x=dates_ed, y=ed_p_in[!, 2] / 100.0, name="ED P In", line_shape="hv"),
])

regup_da_out = read_variable(
    result_merch_DA,
    "BidReserveVariableOut__VariableReserve__ReserveUp__Reg_Up",
)
regup_da_out_realized = vcat([values(vdf)[!, 1][1:24] for vdf in values(regup_da_out)]...)

regup_da_in = read_variable(
    result_merch_DA,
    "BidReserveVariableIn__VariableReserve__ReserveUp__Reg_Up",
)
regup_da_in_realized = vcat([values(vdf)[!, 1][1:24] for vdf in values(regup_da_in)]...)

regup_uc_out = read_realized_variable(
    results_uc,
    "ActivePowerReserveVariable__VariableReserve__ReserveUp__Reg_Up",
)

regup_ed_out = read_realized_variable(
    results_ed,
    "ActivePowerReserveVariable__VariableReserve__ReserveUp__Reg_Up",
)

regup_rt_out = read_variable(
    result_merch_RT,
    "BidReserveVariableOut__VariableReserve__ReserveUp__Reg_Up",
)
regup_rt_out_realized = vcat([values(vdf)[!, 1][1] for vdf in values(regup_rt_out)]...)

regup_rt_in = read_variable(
    result_merch_RT,
    "BidReserveVariableIn__VariableReserve__ReserveUp__Reg_Up",
)
regup_rt_in_realized = vcat([values(vdf)[!, 1][1] for vdf in values(regup_rt_in)]...)

slackup = read_variable(result_merch_RT, "SlackReserveUp__HybridSystem")
slackdn = read_variable(result_merch_RT, "SlackReserveDown__HybridSystem")
slackup_regup = vcat(
    [values(vdf)[!, "(\"317_Hybrid\", \"Reg_Up\")"][1:12] for vdf in values(slackup)]...,
)
slackdn_regup = vcat(
    [values(vdf)[!, "(\"317_Hybrid\", \"Reg_Up\")"][1:12] for vdf in values(slackdn)]...,
)

p2 = plot([
    #scatter(x=dates_uc, y=regup_da_out_realized, name="RegUp DA Bid Out", line_shape="hv"),
    #scatter(x=dates_uc, y=regup_da_in_realized, name="RegUp DA Bid In", line_shape="hv"),
    scatter(
        x=dates_uc,
        y=regup_da_out_realized + regup_da_in_realized,
        name="RegUp DA Bid Out+In",
        line_shape="hv",
    ),
    scatter(
        x=regup_uc_out[!, 1],
        y=regup_uc_out[!, 2] / 100.0,
        name="UC RegUp",
        line_shape="hv",
    ),
    scatter(
        x=regup_ed_out[!, 1],
        y=regup_ed_out[!, 2] / 100.0,
        name="ED RegUp",
        line_shape="hv",
    ),
    scatter(
        x=dates_uc,
        y=regup_rt_out_realized + regup_rt_in_realized,
        name="RegUp RT Bid Out+In",
        line_shape="hv",
    ),
    scatter(x=dates_ed, y=-slackup_regup, line_shape="hv", name="- SlackUp RegUp"),
    scatter(x=dates_ed, y=slackdn_regup, line_shape="hv", name="SlackDown RegUp"),
])

sum(slackup_regup)
plot(scatter(x=dates_ed, y=slackup_regup))

total_res_da = read_variable(result_merch_DA, "TotalReserve__HybridSystem")
total_res_da_realized = vcat(
    [
        values(vdf)[!, "(\"317_Hybrid\", \"Reg_Up\")"][1:288] for
        vdf in values(total_res_da)
    ]...,
)

total_res_uc = read_variable(results_uc, "TotalReserve__HybridSystem")
total_res_uc_realized = vcat(
    [
        values(vdf)[!, "(\"317_Hybrid\", \"Reg_Up\")"][1:24] for vdf in values(total_res_uc)
    ]...,
)

total_res_rt = read_variable(result_merch_RT, "TotalReserve__HybridSystem")
total_res_rt_realized = vcat(
    [
        values(vdf)[!, "(\"317_Hybrid\", \"Reg_Up\")"][1:12] for vdf in values(total_res_rt)
    ]...,
)

plot([
    scatter(
        x=dates_ed,
        y=total_res_da_realized,
        line_shape="hv",
        name="Merch DA Tot Reserve RegUp",
    ),
    scatter(
        x=dates_uc,
        y=total_res_uc_realized,
        line_shape="hv",
        name="UC Tot Reserve RegUp",
    ),
    scatter(
        x=dates_ed,
        y=total_res_rt_realized,
        line_shape="hv",
        name="Merch RT Tot Reserve RegUp",
    ),
])

#ucmod = sim.models.decision_models[2]
#rt_merch = sim.models.decision_models[3]

product_name = "Reg_Down"
total_res_da = read_variable(result_merch_DA, "TotalReserve__HybridSystem")
total_res_da_realized = vcat(
    [
        values(vdf)[!, "(\"317_Hybrid\", \"Reg_Up\")"][1:288] for
        vdf in values(total_res_da)
    ]...,
)

total_res_uc = read_variable(results_uc, "TotalReserve__HybridSystem")
total_res_uc_realized = vcat(
    [
        values(vdf)[!, "(\"317_Hybrid\", \"Reg_Up\")"][1:24] for vdf in values(total_res_uc)
    ]...,
)

total_res_rt = read_variable(result_merch_RT, "TotalReserve__HybridSystem")
total_res_rt_realized = vcat(
    [
        values(vdf)[!, "(\"317_Hybrid\", \"Reg_Up\")"][1:12] for vdf in values(total_res_rt)
    ]...,
)

plot([
    scatter(
        x=dates_ed,
        y=total_res_da_realized,
        line_shape="hv",
        name="Merch DA Tot Reserve RegUp",
    ),
    scatter(
        x=dates_uc,
        y=total_res_uc_realized,
        line_shape="hv",
        name="UC Tot Reserve RegUp",
    ),
    scatter(
        x=dates_ed,
        y=total_res_rt_realized,
        line_shape="hv",
        name="Merch RT Tot Reserve RegUp",
    ),
])

### RegDown

regdn_da_out = read_variable(
    result_merch_DA,
    "BidReserveVariableOut__VariableReserve__ReserveDown__Reg_Down",
)
regdn_da_out_realized = vcat([values(vdf)[!, 1][1:24] for vdf in values(regdn_da_out)]...)

regdn_da_in = read_variable(
    result_merch_DA,
    "BidReserveVariableIn__VariableReserve__ReserveDown__Reg_Down",
)
regdn_da_in_realized = vcat([values(vdf)[!, 1][1:24] for vdf in values(regdn_da_in)]...)

regdn_uc_out = read_realized_variable(
    results_uc,
    "ActivePowerReserveVariable__VariableReserve__ReserveDown__Reg_Down",
)

regdn_ed_out = read_realized_variable(
    results_ed,
    "ActivePowerReserveVariable__VariableReserve__ReserveDown__Reg_Down",
)

regdn_rt_out = read_variable(
    result_merch_RT,
    "BidReserveVariableOut__VariableReserve__ReserveDown__Reg_Down",
)
regdn_rt_out_realized = vcat([values(vdf)[!, 1][1] for vdf in values(regdn_rt_out)]...)

regdn_rt_in = read_variable(
    result_merch_RT,
    "BidReserveVariableIn__VariableReserve__ReserveDown__Reg_Down",
)
regdn_rt_in_realized = vcat([values(vdf)[!, 1][1] for vdf in values(regdn_rt_in)]...)

slackup_rdn = vcat(
    [values(vdf)[!, "(\"317_Hybrid\", \"Reg_Down\")"][1:12] for vdf in values(slackup)]...,
)
slackdn = read_variable(result_merch_RT, "SlackReserveDown__HybridSystem")
slackdn_rdn = vcat(
    [values(vdf)[!, "(\"317_Hybrid\", \"Reg_Down\")"][1:12] for vdf in values(slackdn)]...,
)

p2 = plot([
    #scatter(x=dates_uc, y=regup_da_out_realized, name="RegUp DA Bid Out", line_shape="hv"),
    #scatter(x=dates_uc, y=regup_da_in_realized, name="RegUp DA Bid In", line_shape="hv"),
    scatter(
        x=dates_uc,
        y=regdn_da_out_realized + regdn_da_in_realized,
        name="RegDown DA Bid Out+In",
        line_shape="hv",
    ),
    scatter(
        x=regdn_uc_out[!, 1],
        y=regdn_uc_out[!, 2] / 100.0,
        name="UC RegDown",
        line_shape="hv",
    ),
    scatter(
        x=regdn_ed_out[!, 1],
        y=regdn_ed_out[!, 2] / 100.0,
        name="ED RegDown",
        line_shape="hv",
    ),
    scatter(
        x=dates_uc,
        y=regdn_rt_out_realized + regdn_rt_in_realized,
        name="RegDown RT Bid Out+In",
        line_shape="hv",
    ),
    scatter(x=dates_ed, y=-slackup_rdn, line_shape="hv", name="- SlackUp RegDown"),
    scatter(x=dates_ed, y=slackdn_rdn, line_shape="hv", name="SlackDown RegDown"),
])

# JuMP._TERM_LIMIT_FOR_PRINTING[] = 10000
JuMP._TERM_LIMIT_FOR_PRINTING[] = 60

cons = decision_optimizer_DA.internal.container.constraints
for k in keys(cons)
    println(k)
end

cons[PowerSimulations.ConstraintKey{HybridSystemsSimulations.CyclingDischarge, HybridSystem}(
    "",
)]

exprs = decision_optimizer_DA.internal.container.expressions
for k in keys(exprs)
    println(k)
end

exprs[PowerSimulations.ExpressionKey{
    HybridSystemsSimulations.DischargeServedReserveUpExpression,
    HybridSystem,
}(
    "",
)]
