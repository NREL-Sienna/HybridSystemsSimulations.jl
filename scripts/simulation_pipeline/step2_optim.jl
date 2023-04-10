bus_name = "chuhsi"

sys = sys_rts_rt
sys.internal.ext = Dict{String, DataFrame}()
dic = PSY.get_ext(sys)

dic["λ_da_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)

m = DecisionModel(
    MerchantHybridEnergyCase,
    ProblemTemplate(CopperPlatePowerModel),
    sys,
    optimizer=Xpress.Optimizer,
    calculate_conflict=true,
    store_variable_names=true,
)
PSI.build!(m, output_dir=pwd())
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
