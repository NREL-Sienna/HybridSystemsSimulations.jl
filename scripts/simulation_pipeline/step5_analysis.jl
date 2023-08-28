# Centralized Profit
p_out_opt =
    read_realized_variable(results_ed_dcp, "ActivePowerOutVariable__HybridSystem")[!, 2] /
    100.0
p_in_opt =
    read_realized_variable(results_ed_dcp, "ActivePowerInVariable__HybridSystem")[!, 2] /
    100.0

centralized_profit = sum((p_out_opt - p_in_opt) .* prices_ed_dcp * 100.0 * (5 / 60))
best_case_profit = res.optimizer_stats[1, "objective_value"]
after_da_profit = res_upd.optimizer_stats[1, "objective_value"]

plot(
    [
        scatter(x=dates_uc, y=da_bid_out - da_bid_in, name="DA bids", line_shape="hv"),
        scatter(
            x=dates_ed,
            y=dart,
            name="DART Forecast [\$/MWh]",
            yaxis="y2",
            line_shape="hv",
        ),
    ],
    Layout(
        xaxis_title="Time",
        yaxis_title="Bids [pu]",
        yaxis2=attr(
            title="DART [\$/MWh]",
            overlaying="y",
            side="right",
            autorange=false,
            range=[-50, 50],
        ),
    ),
)

# Dart Profit
da_bids_in_rt = [da_bid_out[tmap[t]] - da_bid_in[tmap[t]] for t in T_rt]
dart_profit = sum(dart .* da_bids_in_rt) * 100.0 * (5 / 60)

# Change in prices
plot(
    [
        scatter(x=dates_uc, y=prices_uc_dcp, name="λ_DA Initial", line_shape="hv"),
        scatter(x=dates_uc, y=prices_da_fix, name="λ_DA Lock Hybrid Bids", line_shape="hv"),
    ],
    Layout(xaxis_title="Time", yaxis_title="Price [\$/MWh]"),
)

# DART updates
plot(
    [
        scatter(x=dates_uc, y=da_bid_out - da_bid_in, name="DA bids", line_shape="hv"),
        scatter(
            x=dates_ed,
            y=dart,
            name="DART Forecast [\$/MWh]",
            yaxis="y2",
            line_shape="hv",
        ),
        scatter(
            x=dates_ed,
            y=dart_new,
            name="Realized DART [\$/MWh]",
            yaxis="y2",
            line_shape="hv",
        ),
    ],
    Layout(
        xaxis_title="Time",
        yaxis_title="Bids [pu]",
        yaxis2=attr(
            title="DART [\$/MWh]",
            overlaying="y",
            side="right",
            autorange=false,
            range=[-50, 50],
        ),
    ),
)

# Profits and Losses with new DART
new_dart_profit = sum(dart_new .* da_bids_in_rt) * 100.0 * (5 / 60)
after_da_profit - new_dart_profit

# Comparison Centralized vs Merchant Dispatch in RT
plot(
    [
        scatter(
            x=dates_ed,
            y=p_out_centr - p_in_centr,
            name="Centralized Hybrid Power",
            line_shape="hv",
        ),
        scatter(
            x=dates_ed,
            y=p_out_upd - p_in_upd,
            name="Updated Merchant Hybrid Power",
            line_shape="hv",
        ),
        scatter(
            x=dates_ed,
            y=prices_ed_dcp,
            name="RT Price Forecast [\$/MWh]",
            yaxis="y2",
            line_shape="hv",
        ),
    ],
    Layout(
        xaxis_title="Time",
        yaxis_title="Power [pu]",
        yaxis2=attr(title="Price [\$/MWh]", overlaying="y", side="right"),
    ),
)

# Battery usage
plot(
    [
        scatter(
            x=dates_ed,
            y=p_ds_old - p_ch_old,
            name="Initial Expected Storage Use",
            line_shape="hv",
        ),
        scatter(
            x=dates_ed,
            y=p_ds_upd - p_ch_upd,
            name="Updated Expected Battery Use",
            line_shape="hv",
        ),
    ],
    Layout(xaxis_title="Time", yaxis_title="Power [pu]"),
)

# Comparison Centralized vs Merchant Dispatch in DA
plot(
    [
        scatter(
            x=dates_uc,
            y=da_bid_out - da_bid_in,
            name="DA Merchant Bids [pu]",
            line_shape="hv",
        ),
        scatter(
            x=dates_uc,
            y=p_out_centr_da - p_in_centr_da,
            name="Centralized DA Hybrid Dispatch [pu]",
            line_shape="hv",
        ),
        scatter(
            x=dates_uc,
            y=prices_uc_dcp - prices_da_fix,
            name="DA Price Forecast Error (Old - New) [\$/MWh]",
            yaxis="y2",
            line_shape="hv",
            line=attr(color="black"),
        ),
    ],
    Layout(
        xaxis_title="Time",
        yaxis_title="Bids and Power [pu]",
        yaxis2=attr(
            title="Price Error [\$/MWh]",
            overlaying="y",
            side="right",
            autorange=false,
            range=[-50, 50],
        ),
    ),
)
