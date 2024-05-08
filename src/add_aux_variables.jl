function PSI.calculate_aux_variable_value!(
    container::PSI.OptimizationContainer,
    ::PSI.AuxVarKey{CyclingChargeUsage, T},
    system::PSY.System,
) where {T <: PSY.HybridSystem}
    devices_hybrids = PSI.get_available_components(T, system)
    devices = [d for d in devices_hybrids if PSY.get_storage(d) !== nothing]
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    charge_var = PSI.get_variable(container, BatteryCharge(), T)
    aux_variable_container = PSI.get_aux_variable(container, CyclingChargeUsage(), T)
    for d in devices
        name = PSY.get_name(d)
        storage = PSY.get_storage(d)
        efficiency = PSY.get_efficiency(storage)
        for t in time_steps
            if !PSY.has_service(d, PSY.VariableReserve)
                aux_variable_container[name, t] =
                    efficiency.in * fraction_of_hour * PSI.jump_value(charge_var[name, t])
            else
                ch_served_reg_up =
                    PSI.get_expression(container, ChargeServedReserveUpExpression(), T)
                ch_served_reg_dn =
                    PSI.get_expression(container, ChargeServedReserveDownExpression(), T)
                aux_variable_container[name, t] =
                    efficiency.in *
                    fraction_of_hour *
                    (
                        PSI.jump_value(charge_var[name, t]) +
                        PSI.jump_value(ch_served_reg_dn[name, t]) -
                        PSI.jump_value(ch_served_reg_up[name, t])
                    )
            end
        end
    end

    return
end

function PSI.calculate_aux_variable_value!(
    container::PSI.OptimizationContainer,
    ::PSI.AuxVarKey{CyclingDischargeUsage, T},
    system::PSY.System,
) where {T <: PSY.HybridSystem}
    devices_hybrids = PSI.get_available_components(T, system)
    devices = [d for d in devices_hybrids if PSY.get_storage(d) !== nothing]
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    discharge_var = PSI.get_variable(container, BatteryDischarge(), T)
    aux_variable_container = PSI.get_aux_variable(container, CyclingDischargeUsage(), T)
    for d in devices
        name = PSY.get_name(d)
        storage = PSY.get_storage(d)
        efficiency = PSY.get_efficiency(storage)
        for t in time_steps
            if !PSY.has_service(d, PSY.VariableReserve)
                aux_variable_container[name, t] =
                    (1.0 / efficiency.out) *
                    fraction_of_hour *
                    PSI.jump_value(discharge_var[name, t])
            else
                ds_served_reg_up =
                    PSI.get_expression(container, DischargeServedReserveUpExpression(), T)
                ds_served_reg_dn =
                    PSI.get_expression(container, DischargeServedReserveDownExpression(), T)
                aux_variable_container[name, t] =
                    (1.0 / efficiency.out) *
                    fraction_of_hour *
                    (
                        PSI.jump_value(discharge_var[name, t]) +
                        PSI.jump_value(ds_served_reg_up[name, t]) -
                        PSI.jump_value(ds_served_reg_dn[name, t])
                    )
            end
        end
    end

    return
end
