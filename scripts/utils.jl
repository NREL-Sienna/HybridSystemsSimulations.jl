using TimeSeries

function get_da_max_active_power_series(r_gen, starttime, steps::Int)
    ta = get_time_series_array(
        SingleTimeSeries,
        r_gen,
        "max_active_power",
        start_time=starttime,
        len=24 * steps,
    )
    return DataFrame(DateTime=timestamp(ta), MaxPower=values(ta))
end

function get_rt_max_active_power_series(r_gen, starttime, steps::Int)
    ta = get_time_series_array(
        SingleTimeSeries,
        r_gen,
        "max_active_power",
        start_time=starttime,
        len=24 * 12 * steps,
    )
    return DataFrame(DateTime=timestamp(ta), MaxPower=values(ta))
end

function get_battery_params(b_gen::GenericBattery)
    battery_params_names = [
        "initial_energy",
        "SoC_min",
        "SoC_max",
        "P_ch_min",
        "P_ch_max",
        "P_ds_min",
        "P_ds_max",
        "η_in",
        "η_out",
    ]
    SoC_min, SoC_max = get_state_of_charge_limits(b_gen)
    P_ch_min, P_ch_max = get_input_active_power_limits(b_gen)
    P_ds_min, P_ds_max = get_output_active_power_limits(b_gen)
    η_in, η_out = get_efficiency(b_gen)
    battery_params_vals = [
        get_initial_energy(b_gen),
        SoC_min,
        SoC_max,
        P_ch_min,
        P_ch_max,
        P_ds_min,
        P_ds_max,
        η_in,
        η_out,
    ]
    return DataFrame(ParamName=battery_params_names, Value=battery_params_vals)
end

function get_thermal_params(t_gen)
    P_min, P_max = get_active_power_limits(t_gen)
    # TODO Implement the proper three part cost
    three_cost = get_operation_cost(t_gen)
    first_part = three_cost.variable[1]
    second_part = three_cost.variable[2]
    slope = (second_part[1] - first_part[1]) / (second_part[2] - first_part[2]) # $/MWh
    fix_cost = three_cost.fixed # $/h    
    return DataFrame(
        ParamName=["P_min", "P_max", "C_var", "C_fix"],
        Value=[P_min, P_max, slope, fix_cost],
    )
end

function get_row_val(df, row_name)
    return df[only(findall(==(row_name), df.ParamName)), :]["Value"]
end
