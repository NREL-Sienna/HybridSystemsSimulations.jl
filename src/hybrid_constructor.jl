function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ArgumentConstructStage,
    model::PSI.DeviceModel{T, D},
    ::Type{S},
) where {T <: PSY.HybridSystem, D <: HybridEnergyOnlyDispatch, S <: PM.AbstractPowerModel}
    devices = PSI.get_available_components(T, sys)
    # Add Common Variables
    PSI.add_variables!(container, PSI.ActivePowerOutVariable, devices, D())
    PSI.add_variables!(container, PSI.ActivePowerInVariable, devices, D())
    PSI.add_variables!(container, PSI.ReservationVariable, devices, D())

    PSI.add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )

    PSI.add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )

    PSI.add_feedforward_arguments!(container, model, devices)

    if PSI.has_service_model(model)
        error("Services are not supported by $D")
    end

    ### Add Component Variables ###

    _hybrids_with_thermal = [d for d in devices if PSY.get_thermal_unit(d) !== nothing]
    _hybrids_with_renewable = [d for d in devices if PSY.get_renewable_unit(d) !== nothing]
    _hybrids_with_storage = [d for d in devices if PSY.get_storage(d) !== nothing]
    _hybrids_with_loads = [d for d in devices if PSY.get_electric_load(d) !== nothing]

    # Thermal
    PSI.add_variables!(container, ThermalPower, _hybrids_with_thermal, D())
    PSI.add_variables!(container, ThermalStatus, _hybrids_with_thermal, D())

    # Renewable
    PSI.add_variables!(container, RenewablePower, _hybrids_with_renewable, D())

    # Storage
    PSI.add_variables!(container, BatteryCharge, _hybrids_with_storage, D())
    PSI.add_variables!(container, BatteryDischarge, _hybrids_with_storage, D())
    PSI.add_variables!(container, PSI.EnergyVariable, _hybrids_with_storage, D())
    PSI.add_variables!(container, BatteryStatus, _hybrids_with_storage, D())

    PSI.initial_conditions!(container, _hybrids_with_storage, D())

    ### Add Parameters ###
    PSI.add_parameters!(container, RenewablePowerTimeSeries, _hybrids_with_renewable, model)
    PSI.add_parameters!(container, ElectricLoadTimeSeries, _hybrids_with_loads, model)

    ### Objective Function ###
    PSI.objective_function!(container, devices, model, S)
    return
end

function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ModelConstructStage,
    model::PSI.DeviceModel{T, D},
    ::Type{S},
) where {
    T <: PSY.HybridSystem,
    D <: HybridEnergyOnlyDispatch,
    S <: PM.AbstractActivePowerModel,
}
    devices = PSI.get_available_components(T, sys)

    # Constraints
    PSI.add_constraints!(
        container,
        PSI.InputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerInVariable,
        devices,
        model,
        S,
    )
    PSI.add_constraints!(
        container,
        PSI.OutputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        S,
    )

    # Binary Hybrid Output or Input
    PSI.add_constraints!(container, StatusOutOn, devices, model, S)

    PSI.add_constraints!(container, StatusInOn, devices, model, S)

    # Energy Asset Balance
    PSI.add_constraints!(container, EnergyAssetBalance, devices, model, S)

    ### Add Component Constraints ###
    _hybrids_with_thermal = [d for d in devices if PSY.get_thermal_unit(d) !== nothing]
    _hybrids_with_renewable = [d for d in devices if PSY.get_renewable_unit(d) !== nothing]
    _hybrids_with_storage = [d for d in devices if PSY.get_storage(d) !== nothing]

    # Thermal
    PSI.add_constraints!(container, ThermalOnVariableOn, _hybrids_with_thermal, model, S)
    PSI.add_constraints!(container, ThermalOnVariableOff, _hybrids_with_thermal, model, S)

    # Storage
    PSI.add_constraints!(container, BatteryStatusChargeOn, _hybrids_with_storage, model, S)
    PSI.add_constraints!(
        container,
        BatteryStatusDischargeOn,
        _hybrids_with_storage,
        model,
        S,
    )
    PSI.add_constraints!(container, BatteryBalance, _hybrids_with_storage, model, S)
    PSI.add_constraints!(container, CyclingCharge, _hybrids_with_storage, model, S)
    PSI.add_constraints!(container, CyclingDischarge, _hybrids_with_storage, model, S)

    # Renewable
    PSI.add_constraints!(
        container,
        RenewableActivePowerLimitConstraint,
        _hybrids_with_renewable,
        model,
        S,
    )

    return
end
