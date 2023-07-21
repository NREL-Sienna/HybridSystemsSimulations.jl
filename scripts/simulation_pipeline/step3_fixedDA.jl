sys_fixDA = build_system(PSISystems, "modified_RTS_GMLC_DA_sys_noForecast")
horizon_fixDA = 72
interval_fixDA = Hour(72)
bus_to_add = "Chuhsi" # "Barton"
modify_ren_curtailment_cost!(sys_fixDA)
add_hybrid_to_chuhsi_bus!(sys_fixDA)


h = first(get_components(HybridSystem, sys_fixDA))
h.ext["DABids"] = bid_df

transform_single_time_series!(sys_fixDA, horizon_fixDA, interval_fixDA)


template_uc_copperplate = get_uc_copperplate_template(sys_fixDA)
set_device_model!(
    template_uc_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridEnergyOnlyFixedDA;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)

m_fixDA = DecisionModel(
    template_uc_copperplate,
    sys_fixDA;
    name="UC",
    optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => mipgap),
    initial_time=starttime,
    system_to_file=false,
    initialize_model=true,
    optimizer_solve_log_print=true,
    direct_mode_optimizer=true,
    store_variable_names=true,
)

build!(m_fixDA, output_dir=pwd())
solve!(m_fixDA)

res_fixDA = ProblemResults(m_fixDA)

p_out = read_variable(res_fixDA, "ActivePowerOutVariable__HybridSystem")
p_in = read_variable(res_fixDA, "ActivePowerInVariable__HybridSystem")
sum(p_in[!, 2] / 100.0 - bid_df[!, "BidIn"])

prices_da_fix = read_dual(res_fixDA, "CopperPlateBalanceConstraint__System")[!, 2] / 100.0

plot([
    scatter(x=dates_uc, y=prices_uc_dcp, name="λ_DA", line_shape="hv"),
    scatter(x=dates_uc, y=prices_da_fix, name="λ_DA FixHybrid", line_shape="hv"),
])

dart_new = [prices_da_fix[tmap[t]] - prices_ed_dcp[t] for t in T_rt]

plot([
    scatter(x=dates_uc, y=da_bid_out, name="bid_out", line_shape="hv"),
    scatter(x=dates_uc, y=-da_bid_in, name="bid_in", line_shape="hv"),
    scatter(x=dates_ed, y=dart_new / 8.0, name="New dart/8", line_shape="hv"),
])

plot([
    scatter(x=dates_uc, y=prices_da_fix / 8, name="new DA prices", line_shape="hv"),
    scatter(x=dates_uc, y=prices_uc_dcp / 8, name="old DA prices", line_shape="hv"),
    scatter(x=dates_uc, y=da_bid_out, name="bid_out", line_shape="hv"),
    scatter(x=dates_uc, y=-da_bid_in, name="bid_in", line_shape="hv"),
    scatter(x=dates_uc, y=p_re_da, name="p_re_DA", line_shape="hv"),
])

DA_prices_upd = DataFrame()
DA_prices_upd[!, "DateTime"] = dates_uc
DA_prices_upd[!, "Chuhsi"] = prices_da_fix

CSV.write("scripts/simulation_pipeline/inputs/chuhsi_DA_prices_updated.csv", DA_prices_upd)
CSV.write("scripts/simulation_pipeline/inputs/chuhsi_bid_fixed.csv", bid_df)
