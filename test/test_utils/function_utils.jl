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

function modify_ren_curtailment_cost!(sys)
    rdispatch = get_components(RenewableDispatch, sys)
    for ren in rdispatch
        # We consider 15 $/MWh as a reasonable cost for renewable curtailment
        cost = TwoPartCost(15.0, 0.0)
        set_operation_cost!(ren, cost)
    end
    return
end

function _build_battery(
    bus::PSY.Bus,
    energy_capacity,
    rating,
    efficiency_in,
    efficiency_out,
)
    name = string(bus.number) * "_BATTERY"
    device = GenericBattery(;
        name=name,
        available=true,
        bus=bus,
        prime_mover_type=PSY.PrimeMovers.BA,
        initial_energy=energy_capacity / 2,
        state_of_charge_limits=(min=energy_capacity * 0.05, max=energy_capacity),
        rating=rating,
        active_power=rating,
        input_active_power_limits=(min=0.0, max=rating),
        output_active_power_limits=(min=0.0, max=rating),
        efficiency=(in=efficiency_in, out=efficiency_out),
        reactive_power=0.0,
        reactive_power_limits=nothing,
        base_power=100.0,
        operation_cost=PSY.TwoPartCost(0.0, 0.0),
    )
    return device
end

function add_battery_to_bus!(sys::System, bus_name::String)
    bus = get_component(Bus, sys, bus_name)
    bat = _build_battery(bus, 4.0, 2.0, 0.93, 0.93)
    add_component!(sys, bat)
    return
end

function add_hybrid_to_chuhsi_bus!(sys::System)
    bus = get_component(Bus, sys, "Chuhsi")
    bat = _build_battery(bus, 4.0, 2.0, 0.93, 0.93)
    # Wind is taken from Bus 317: Chuhsi
    # Thermal and Load is taken from adjacent bus 318: Clark
    ren_name = "317_WIND_1"
    thermal_name = "318_CC_1"
    load_name = "Clark"
    renewable = get_component(StaticInjection, sys, ren_name)
    thermal = get_component(StaticInjection, sys, thermal_name)
    load = get_component(PowerLoad, sys, load_name)
    # Create the Hybrid
    hybrid_name = string(bus.number) * "_Hybrid"
    hybrid = PSY.HybridSystem(
        name=hybrid_name,
        available=true,
        status=true,
        bus=bus,
        active_power=1.0,
        reactive_power=0.0,
        base_power=100.0,
        operation_cost=TwoPartCost(nothing),
        thermal_unit=thermal, #new_th,
        electric_load=load, #new_load,
        storage=bat,
        renewable_unit=renewable, #new_ren,
        interconnection_impedance=0.0 + 0.0im,
        interconnection_rating=nothing,
        input_active_power_limits=(min=0.0, max=10.0),
        output_active_power_limits=(min=0.0, max=10.0),
        reactive_power_limits=nothing,
    )
    # Add Hybrid
    add_component!(sys, hybrid)
    return
end
