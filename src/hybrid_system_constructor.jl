### ArgumentConstruct Only Energy ###
function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ArgumentConstructStage,
    model::PSI.DeviceModel{T, D},
    network_model::PSI.NetworkModel{S},
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
        network_model,
    )

    PSI.add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        network_model,
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
    if !isempty(_hybrids_with_thermal)
        PSI.add_variables!(container, ThermalPower, _hybrids_with_thermal, D())
        PSI.add_variables!(container, ThermalStatus, _hybrids_with_thermal, D())
    end

    # Renewable
    if !isempty(_hybrids_with_renewable)
        PSI.add_variables!(container, RenewablePower, _hybrids_with_renewable, D())
    end

    # Storage
    if !isempty(_hybrids_with_storage)
        PSI.add_variables!(container, BatteryCharge, _hybrids_with_storage, D())
        PSI.add_variables!(container, BatteryDischarge, _hybrids_with_storage, D())
        PSI.add_variables!(container, PSI.EnergyVariable, _hybrids_with_storage, D())
        PSI.add_variables!(container, BatteryStatus, _hybrids_with_storage, D())

        PSI.initial_conditions!(container, _hybrids_with_storage, D())
    end

    ### Add Parameters ###
    if !isempty(_hybrids_with_renewable)
        PSI.add_parameters!(
            container,
            RenewablePowerTimeSeries,
            _hybrids_with_renewable,
            model,
        )
    end
    if !isempty(_hybrids_with_loads)
        PSI.add_parameters!(container, ElectricLoadTimeSeries, _hybrids_with_loads, model)
    end

    ### Objective Function ###
    PSI.objective_function!(container, devices, model, network_model)
    return
end

### ModelConstruct Hybrid Only Energy ###
function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ModelConstructStage,
    model::PSI.DeviceModel{T, D},
    network_model::PSI.NetworkModel{S},
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
        network_model,
    )
    PSI.add_constraints!(
        container,
        PSI.OutputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        network_model,
    )

    # Binary Hybrid Output or Input
    PSI.add_constraints!(container, StatusOutOn, devices, model, network_model)

    PSI.add_constraints!(container, StatusInOn, devices, model, network_model)

    # Energy Asset Balance
    PSI.add_constraints!(container, EnergyAssetBalance, devices, model, network_model)

    ### Add Component Constraints ###
    _hybrids_with_thermal = [d for d in devices if PSY.get_thermal_unit(d) !== nothing]
    _hybrids_with_renewable = [d for d in devices if PSY.get_renewable_unit(d) !== nothing]
    _hybrids_with_storage = [d for d in devices if PSY.get_storage(d) !== nothing]

    # Thermal
    if !isempty(_hybrids_with_thermal)
        PSI.add_constraints!(
            container,
            ThermalOnVariableOn,
            _hybrids_with_thermal,
            model,
            network_model,
        )
        PSI.add_constraints!(
            container,
            ThermalOnVariableOff,
            _hybrids_with_thermal,
            model,
            network_model,
        )
    end

    # Storage
    if !isempty(_hybrids_with_storage)
        PSI.add_constraints!(
            container,
            BatteryStatusChargeOn,
            _hybrids_with_storage,
            model,
            network_model,
        )
        PSI.add_constraints!(
            container,
            BatteryStatusDischargeOn,
            _hybrids_with_storage,
            model,
            network_model,
        )
        PSI.add_constraints!(
            container,
            BatteryBalance,
            _hybrids_with_storage,
            model,
            network_model,
        )
        PSI.add_constraints!(
            container,
            CyclingCharge,
            _hybrids_with_storage,
            model,
            network_model,
        )
        PSI.add_constraints!(
            container,
            CyclingDischarge,
            _hybrids_with_storage,
            model,
            network_model,
        )
    end

    # Renewable
    if !isempty(_hybrids_with_renewable)
        PSI.add_constraints!(
            container,
            RenewableActivePowerLimitConstraint,
            _hybrids_with_renewable,
            model,
            network_model,
        )
    end

    return
end

### ArgumentConstruct FixedDA ###
function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ArgumentConstructStage,
    model::PSI.DeviceModel{T, D},
    network_model::PSI.NetworkModel{S},
) where {T <: PSY.HybridSystem, D <: HybridEnergyOnlyFixedDA, S <: PM.AbstractPowerModel}
    devices = PSI.get_available_components(T, sys)
    # Add Common Variables
    PSI.add_variables!(container, PSI.ActivePowerOutVariable, devices, D())
    PSI.add_variables!(container, PSI.ActivePowerInVariable, devices, D())

    PSI.add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerInVariable,
        devices,
        model,
        network_model,
    )

    PSI.add_to_expression!(
        container,
        PSI.ActivePowerBalance,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        network_model,
    )

    PSI.add_feedforward_arguments!(container, model, devices)

    if PSI.has_service_model(model)
        error("Services are not supported by $D")
    end

    return
end

### ModelConstruct Hybrid Only Energy ###
function PSI.construct_device!(
    container::PSI.OptimizationContainer,
    sys::PSY.System,
    ::PSI.ModelConstructStage,
    model::PSI.DeviceModel{T, D},
    network_model::PSI.NetworkModel{S},
) where {
    T <: PSY.HybridSystem,
    D <: HybridEnergyOnlyFixedDA,
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
        network_model,
    )
    PSI.add_constraints!(
        container,
        PSI.OutputActivePowerVariableLimitsConstraint,
        PSI.ActivePowerOutVariable,
        devices,
        model,
        network_model,
    )

    return
end
