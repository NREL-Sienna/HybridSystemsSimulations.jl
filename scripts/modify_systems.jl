function modify_ren_curtailment_cost!(sys)
    rdispatch = get_components(RenewableDispatch, sys)
    for ren in rdispatch
        # We consider 15 $/MWh as a reasonable cost for renewable curtailment
        cost = TwoPartCost(15.0, 0.0)
        set_operation_cost!(ren, cost)
    end
    th_cheap = get_component(ThermalStandard, sys, "101_STEAM_3")
    set_rating!(th_cheap, 5.2)
    set_active_power_limits!(th_cheap, (min=0.3, max=5.0))
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
        initial_energy=0.0,
        state_of_charge_limits=(min=energy_capacity * 0.0, max=energy_capacity),
        rating=rating,
        active_power=rating,
        input_active_power_limits=(min=0.0, max=rating),
        output_active_power_limits=(min=0.0, max=rating),
        efficiency=(in=efficiency_in, out=efficiency_out),
        reactive_power=0.0,
        reactive_power_limits=nothing,
        base_power=100.0,
        operation_cost=PSY.StorageManagementCost(),
    )
    return device
end

function add_battery_to_bus!(sys::System, bus_name::String)
    bus = get_component(Bus, sys, bus_name)
    bat = _build_battery(bus, 8.0, 4.0, 0.93, 0.93)
    add_component!(sys, bat)
    return
end

function add_hybrid_to_chuhsi_bus!(sys::System; ren_name="317_WIND_1")
    bus = get_component(Bus, sys, "Chuhsi")
    bat = _build_battery(bus, 4.0, 1.0, 0.93, 0.93)
    op_cost = get_operation_cost(bat)
    op_cost.variable = VariableCost(2.0)
    # Wind is taken from Bus 317: Chuhsi
    # Thermal and Load is taken from adjacent bus 318: Clark
    thermal_name = "318_CC_1"
    load_name = "Clark"
    renewable = get_component(StaticInjection, sys, ren_name)
    set_rating!(renewable, 1.0)
    thermal = get_component(StaticInjection, sys, thermal_name)
    set_rating!(thermal, 1.0)
    set_active_power_limits!(thermal, (min=0.0, max=0.95))
    load = get_component(PowerLoad, sys, load_name)
    load = nothing
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
        input_active_power_limits=(min=0.0, max=3.0),
        output_active_power_limits=(min=0.0, max=3.0),
        reactive_power_limits=nothing,
    )
    # Add Hybrid
    add_component!(sys, hybrid)
    return
end

function add_da_forecast_in_5_mins_to_rt!(sys_rts_rt, sys_rts_da; ren_name="317_WIND_1")
    comp_da = get_component(RenewableDispatch, sys_rts_da, ren_name)
    data_ts_object = get_time_series(SingleTimeSeries, comp_da, "max_active_power")
    ini_time = get_initial_timestamp(data_ts_object)
    data_da = values(get_data(data_ts_object))
    comp_rt = get_component(RenewableDispatch, sys_rts_rt, ren_name)
    data_rt = get_data(get_time_series(SingleTimeSeries, comp_rt, "max_active_power"))
    rt_data = [
        data_da[div(k - 1, Int(length(data_rt) / length(data_da))) + 1] for
        k in 1:length(data_rt)
    ]
    new_ts = SingleTimeSeries("max_active_power_da", TimeArray(timestamp(data_rt), rt_data))
    add_time_series!(sys_rts_rt, comp_rt, new_ts)
    return
end
