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

dic = PSY.get_ext(sys_rts_merchant_da)

# Add prices to ext. Only three days.
bus_name = "chuhsi"
dic["λ_da_df"] =
    CSV.read("scripts/cooptimizer_pipeline/inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] =
    CSV.read("scripts/cooptimizer_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic["λ_Reg_Up"] = CSV.read(
    "scripts/cooptimizer_pipeline/inputs/$(bus_name)_RegUp_prices.csv",
    DataFrame,
)
dic["λ_Reg_Down"] = CSV.read(
    "scripts/cooptimizer_pipeline/inputs/$(bus_name)_RegDown_prices.csv",
    DataFrame,
)
dic["λ_Spin_Up_R3"] = CSV.read(
    "scripts/cooptimizer_pipeline/inputs/$(bus_name)_Spin_prices.csv",
    DataFrame,
)
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
    optimizer=Xpress.Optimizer,
    calculate_conflict=true,
    system_to_file=false,
    store_variable_names=true;
    name="MerchantHybridCooptimizer_DA",
)

build!(decision_optimizer_DA, output_dir = mktempdir())

solve!(decision_optimizer_DA)