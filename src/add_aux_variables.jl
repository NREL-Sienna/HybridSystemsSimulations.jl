function PSI.calculate_aux_variable_value!(
    container::PSI.OptimizationContainer,
    ::PSI.AuxVarKey{CumulativeCyclingCharge, T},
    system::PSY.System,
) where {T <: PSY.HybridSystem}
    devices_hybrids = PSI.get_available_components(T, system)
    devices = [d for d in devices_hybrids if PSY.get_storage(d) !== nothing]
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    charge_var = PSI.get_variable(container, BatteryCharge(), T)
    aux_variable_container = PSI.get_aux_variable(container, CumulativeCyclingCharge(), T)
    for d in devices, t in time_steps
        name = PSY.get_name(d)
        storage = PSY.get_storage(d)
        efficiency = PSY.get_efficiency(storage)
        #TODO: add served fraction of reserves
        aux_variable_container[name, t] =
            efficiency.in *
            fraction_of_hour *
            sum(PSI.jump_value(charge_var[name, k]) for k in 1:t)
    end

    return
end

function PSI.calculate_aux_variable_value!(
    container::PSI.OptimizationContainer,
    ::PSI.AuxVarKey{CumulativeCyclingDischarge, T},
    system::PSY.System,
) where {T <: PSY.HybridSystem}
    devices_hybrids = PSI.get_available_components(T, system)
    devices = [d for d in devices_hybrids if PSY.get_storage(d) !== nothing]
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    discharge_var = PSI.get_variable(container, BatteryDischarge(), T)
    aux_variable_container =
        PSI.get_aux_variable(container, CumulativeCyclingDischarge(), T)
    for d in devices, t in time_steps
        name = PSY.get_name(d)
        storage = PSY.get_storage(d)
        efficiency = PSY.get_efficiency(storage)
        #TODO: add served fraction of reserves
        aux_variable_container[name, t] =
            (1.0 / efficiency.out) *
            fraction_of_hour *
            sum(PSI.jump_value(discharge_var[name, k]) for k in 1:t)
    end

    return
end
