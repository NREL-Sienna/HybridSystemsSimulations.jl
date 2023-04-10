sys_upd = build_system(PSISystems, "modified_RTS_GMLC_RT_sys")
bus_to_add = "Chuhsi" # "Barton"
modify_ren_curtailment_cost!(sys_upd)
add_hybrid_to_chuhsi_bus!(sys_upd)

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
