bus_name = "chuhsi"
sys_rts_da_original = build_system(PSISystems, "modified_RTS_GMLC_DA_sys_noForecast")
sys_rts_merchant = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
horizon_merchant_rt = 12 * 24 * 3
horizon_merchant_da = 72
interval_merchant = Dates.Hour(1)
add_da_forecast_in_5_mins_to_rt!(sys_rts_merchant, sys_rts_da_original)

for sys in [sys_rts_merchant]
    bus_to_add = "Chuhsi" # "Barton"
    modify_ren_curtailment_cost!(sys)
    add_hybrid_to_chuhsi_bus!(sys)
    #for l in get_components(PowerLoad, sys)
    #    set_max_active_power!(l, get_max_active_power(l) * 1.3)
    #end
end

transform_single_time_series!(sys_rts_merchant, horizon_merchant_rt, interval_merchant)
sys = sys_rts_merchant
sys.internal.ext = Dict{String, DataFrame}()
dic = PSY.get_ext(sys)

dic["λ_da_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)
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

dic["horizon_RT"] = horizon_merchant_rt
dic["horizon_DA"] = horizon_merchant_da

hy_sys = first(get_components(HybridSystem, sys))
PSY.set_ext!(hy_sys, deepcopy(dic))

m = DecisionModel(
    MerchantHybridCooptimizerCase,
    ProblemTemplate(CopperPlatePowerModel),
    sys,
    optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => mipgap),
    calculate_conflict=true,
    store_variable_names=true,
    initial_time=starttime,
)

PSI.build!(m, output_dir=mktempdir())
PSI.solve!(m)
res = ProblemResults(m)
dic_res = get_variable_values(res)

da_bid_out = dic_res[PSI.VariableKey{EnergyDABidOut, HybridSystem}("")][!, 1]
da_bid_in = dic_res[PSI.VariableKey{EnergyDABidIn, HybridSystem}("")][!, 1]

p_ch_old = dic_res[PSI.VariableKey{HSS.BatteryCharge, HybridSystem}("")][!, 1]
p_ds_old = dic_res[PSI.VariableKey{HSS.BatteryDischarge, HybridSystem}("")][!, 1]

p_th_old = dic_res[PSI.VariableKey{HSS.ThermalPower, HybridSystem}("")][!, 1]

p_re_old = dic_res[PSI.VariableKey{HSS.RenewablePower, HybridSystem}("")][!, 1]

p_out_old = dic_res[PSI.VariableKey{HSS.BatteryCharge, HybridSystem}("")][!, 1]
p_in_old = dic_res[PSI.VariableKey{HSS.BatteryDischarge, HybridSystem}("")][!, 1]

plot([
    scatter(x=dates_uc, y=da_bid_out, name="bid_out", line_shape="hv"),
    scatter(x=dates_uc, y=-da_bid_in, name="bid_in", line_shape="hv"),
    scatter(x=dates_ed, y=dart / 8.0, name="dart/8", line_shape="hv"),
])

bid_df = DataFrame()
bid_df[!, "DateTime"] = dates_uc
bid_df[!, "BidOut"] = da_bid_out
bid_df[!, "BidIn"] = da_bid_in
