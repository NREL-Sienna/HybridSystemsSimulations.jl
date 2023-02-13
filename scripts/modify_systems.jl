function modify_ren_curtailment_cost!(sys)
    rdispatch = get_components(RenewableDispatch, sys)
    for ren in rdispatch
        # We consider 15 $/MWh as a reasonable cost for renewable curtailment
        cost = TwoPartCost(15.0, 0.0)
        set_operation_cost!(ren, cost)
    end
    return
end

function _build_battery(bus::PSY.Bus, energy_capacity, rating, efficiency)
    name = string(bus.number) * "_BATTERY"
    device = GenericBattery(;
        name=name,
        available=true,
        bus=bus,
        prime_mover=PSY.PrimeMovers.BA,
        initial_energy=energy_capacity / 2,
        state_of_charge_limits=(min=energy_capacity * 0.1, max=energy_capacity),
        rating=rating,
        active_power=rating,
        input_active_power_limits=(min=0.0, max=rating),
        output_active_power_limits=(min=0.0, max=rating),
        efficiency=(in=efficiency, out=1.0),
        reactive_power=0.0,
        reactive_power_limits=nothing,
        base_power=100.0,
    )
    return device
end

function add_battery_to_bus!(sys::System, bus_name::String)
    bus = get_component(Bus, sys, bus_name)
    bat = _build_battery(bus, 2.0, 1.0, 0.93)
    add_component!(sys, bat)
    return
end
