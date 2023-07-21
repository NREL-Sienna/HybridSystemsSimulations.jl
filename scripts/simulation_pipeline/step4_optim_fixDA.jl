bus_to_add = "Chuhsi" # "Barton"
sys_upd = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
horizon_merchant_rt = 12 * 24 * 3
horizon_merchant_da = 72
interval_merchant = Dates.Hour(24 * 3)

for sys in [sys_upd]
    bus_to_add = "Chuhsi" # "Barton"
    modify_ren_curtailment_cost!(sys)
    add_hybrid_to_chuhsi_bus!(sys)
    #for l in get_components(PowerLoad, sys)
    #    set_max_active_power!(l, get_max_active_power(l) * 1.3)
    #end
end

transform_single_time_series!(sys_upd, horizon_merchant_rt, interval_merchant)

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
PSI.build!(m_upd, output_dir=pwd())
PSI.solve!(m_upd)
res_upd = ProblemResults(m_upd)
dic_res_upd = get_variable_values(res_upd)

da_bid_out_upd = dic_res_upd[PSI.VariableKey{EnergyDABidOut, HybridSystem}("")][!, 1]
da_bid_in_upd = dic_res_upd[PSI.VariableKey{EnergyDABidIn, HybridSystem}("")][!, 1]

p_out_upd = dic_res_upd[PSI.VariableKey{ActivePowerOutVariable, HybridSystem}("")][!, 1]
p_in_upd = dic_res_upd[PSI.VariableKey{ActivePowerInVariable, HybridSystem}("")][!, 1]

p_ch_upd = dic_res_upd[PSI.VariableKey{HSS.BatteryCharge, HybridSystem}("")][!, 1]
p_ds_upd = dic_res_upd[PSI.VariableKey{HSS.BatteryDischarge, HybridSystem}("")][!, 1]

p_th_upd = dic_res_upd[PSI.VariableKey{HSS.ThermalPower, HybridSystem}("")][!, 1]

p_re_upd = dic_res_upd[PSI.VariableKey{HSS.RenewablePower, HybridSystem}("")][!, 1]
