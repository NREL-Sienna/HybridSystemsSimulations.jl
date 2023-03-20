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

    return
end
