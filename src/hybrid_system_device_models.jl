############## TimeSeries, HybridSystems ##########################

function PSI.get_default_time_series_names(
    ::Type{PSY.HybridSystem},
    ::Type{<:Union{PSI.FixedOutput, AbstractHybridFormulation}},
)
    return Dict{Type{<:PSI.TimeSeriesParameter}, String}(
        RenewablePowerTimeSeries => "RenewableDispatch__max_active_power",
        ElectricLoadTimeSeries => "PowerLoad__max_active_power",
    )
end

function PSI.get_default_attributes(
    ::Type{PSY.HybridSystem},
    ::Type{<:Union{PSI.FixedOutput, AbstractHybridFormulation}},
)
    return Dict{String, Any}("reservation" => true, "storage_reservation" => true)
end

PSI.get_initial_conditions_device_model(
    ::PSI.OperationModel,
    ::PSI.DeviceModel{T, <:AbstractHybridFormulation},
) where {T <: PSY.HybridSystem} = PSI.DeviceModel(T, HybridEnergyOnlyDispatch)

PSI.get_multiplier_value(
    ::RenewablePowerTimeSeries,
    device::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_max_active_power(PSY.get_renewable_unit(device))

PSI.get_multiplier_value(
    ::ElectricLoadTimeSeries,
    device::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_max_active_power(PSY.get_electric_load(device))

############## PSI.ActivePowerInVariable, HybridSystem ####################

PSI.get_variable_binary(
    ::PSI.ActivePowerInVariable,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_lower_bound(
    ::PSI.ActivePowerInVariable,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_input_active_power_limits(d).min
PSI.get_variable_upper_bound(
    ::PSI.ActivePowerInVariable,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_input_active_power_limits(d).max
PSI.get_variable_multiplier(
    ::PSI.ActivePowerInVariable,
    ::Type{<:PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = -1.0
PSI.get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{PSI.InputActivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = PSY.get_input_active_power_limits(device)

############## PSI.ActivePowerOutVariable, HybridSystem ####################
PSI.get_variable_binary(
    ::PSI.ActivePowerOutVariable,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false

PSI.get_variable_upper_bound(
    ::PSI.ActivePowerOutVariable,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_output_active_power_limits(d).max

PSI.get_variable_lower_bound(
    ::PSI.ActivePowerOutVariable,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_output_active_power_limits(d).min

PSI.get_variable_multiplier(
    ::PSI.ActivePowerOutVariable,
    ::Type{<:PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = 1.0

PSI.get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{PSI.OutputActivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = PSY.get_output_active_power_limits(device)

PSY.get_active_power_limits(device::PSY.HybridSystem) =
    PSY.get_output_active_power_limits(device)

############## PSI.Reservation Variables, HybridSystem ####################

PSI.get_variable_binary(
    ::PSI.ReservationVariable,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = true

############### Asset Variables, HybridSystem #####################
PSI.get_default_on_variable(::PSY.HybridSystem) = ThermalStatus()

# Upper Bound
PSI.get_variable_upper_bound(
    ::ThermalPower,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_active_power_limits(PSY.get_thermal_unit(d)).max

PSI.get_variable_upper_bound(
    ::RenewablePower,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_max_active_power(PSY.get_renewable_unit(d))

PSI.get_variable_upper_bound(
    ::BatteryCharge,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_input_active_power_limits(PSY.get_storage(d)).max

PSI.get_variable_upper_bound(
    ::BatteryDischarge,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_output_active_power_limits(PSY.get_storage(d)).max

PSI.get_variable_upper_bound(
    ::PSI.EnergyVariable,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_state_of_charge_limits(PSY.get_storage(d)).max

PSI.get_variable_upper_bound(
    ::ThermalStatus,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = nothing

PSI.get_variable_upper_bound(
    ::BatteryStatus,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = nothing

# Lower Bound
PSI.get_variable_lower_bound(
    ::ThermalPower,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0

PSI.get_variable_lower_bound(
    ::RenewablePower,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0

PSI.get_variable_lower_bound(
    ::BatteryCharge,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0

PSI.get_variable_lower_bound(
    ::BatteryDischarge,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0

PSI.get_variable_lower_bound(
    ::PSI.EnergyVariable,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_state_of_charge_limits(PSY.get_storage(d)).min

PSI.get_variable_lower_bound(
    ::ThermalStatus,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = nothing

PSI.get_variable_lower_bound(
    ::BatteryStatus,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = nothing

# Binaries
PSI.get_variable_binary(
    ::ThermalPower,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_binary(
    ::ThermalStatus,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = true
PSI.get_variable_binary(
    ::RenewablePower,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_binary(
    ::BatteryCharge,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_binary(
    ::BatteryDischarge,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_binary(
    ::PSI.EnergyVariable,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_binary(
    ::BatteryStatus,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = true

PSI.initial_condition_default(
    ::PSI.InitialEnergyLevel,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_initial_energy(PSY.get_storage(d))
PSI.initial_condition_variable(
    ::PSI.InitialEnergyLevel,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSI.EnergyVariable()

################### Reserve Variables ############################

PSI.get_expression_type_for_reserve(
    ::PSI.ActivePowerReserveVariable,
    ::Type{<:PSY.HybridSystem},
    ::Type{<:PSY.Reserve{PSY.ReserveUp}},
) = PSI.ReserveRangeExpressionUB
PSI.get_expression_type_for_reserve(
    ::PSI.ActivePowerReserveVariable,
    ::Type{<:PSY.HybridSystem},
    ::Type{<:PSY.Reserve{PSY.ReserveDown}},
) = PSI.ReserveRangeExpressionLB

PSI.get_variable_multiplier(
    ::Type{<:ComponentReserveVariableType},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 1.0
PSI.get_variable_multiplier(
    ::Type{<:ComponentReserveVariableType},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0
PSI.get_variable_multiplier(
    ::Type{ChargingReserveVariable},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 1.0
PSI.get_variable_multiplier(
    ::Type{ChargingReserveVariable},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0
PSI.get_variable_multiplier(
    ::Type{ThermalReserveVariable},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 1.0
PSI.get_variable_multiplier(
    ::Type{ThermalReserveVariable},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{ReserveVariableOut},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve,
) = 1.0
PSI.get_variable_multiplier(
    ::Type{ReserveVariableIn},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve,
) = 1.0

PSI.get_variable_multiplier(
    ::Type{BidReserveVariableOut},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve,
) = 1.0
PSI.get_variable_multiplier(
    ::Type{BidReserveVariableIn},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve,
) = 1.0

################### Parameters ############################

PSI.get_parameter_multiplier(
    ::PSI.FixValueParameter,
    ::PSY.HybridSystem,
    ::HybridEnergyOnlyFixedDA,
) = 1.0

###################################################################
################### Objective Function ############################
###################################################################

############### Storage costs, HybridSystem #######################
PSI.objective_function_multiplier(
    ::Union{BatteryCharge, BatteryDischarge},
    ::AbstractHybridFormulation,
) = PSI.OBJECTIVE_FUNCTION_POSITIVE

PSI.proportional_cost(
    cost::PSY.OperationalCost,
    ::Union{BatteryCharge, BatteryDischarge},
    ::PSY.HybridSystem,
    U::AbstractHybridFormulation,
) = PSY.get_variable(cost).cost

function PSI.add_proportional_cost!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::U,
    ::W,
) where {
    T <: Union{BatteryCharge, BatteryDischarge},
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    multiplier = PSI.objective_function_multiplier(T(), W())
    for d in devices
        op_cost_data = PSY.get_operation_cost(PSY.get_storage(d))
        isnothing(op_cost_data) && continue
        cost_term = PSI.proportional_cost(op_cost_data, T(), d, W())
        iszero(cost_term) && continue
        for t in PSI.get_time_steps(container)
            PSI._add_proportional_term!(container, T(), d, cost_term * multiplier, t)
        end
    end
    return
end

############### Thermal costs, HybridSystem #######################

PSI.objective_function_multiplier(
    ::Union{ThermalPower, ThermalStatus},
    ::AbstractHybridFormulation,
) = PSI.OBJECTIVE_FUNCTION_POSITIVE

PSI.proportional_cost(
    cost::PSY.OperationalCost,
    ::ThermalStatus,
    ::PSY.HybridSystem,
    U::AbstractHybridFormulation,
) = PSY.get_fixed(cost)

PSI.variable_cost(
    cost::PSY.OperationalCost,
    ::ThermalPower,
    ::PSY.HybridSystem,
    U::AbstractHybridFormulation,
) = PSY.get_variable(cost)

PSI.uses_compact_power(::PSY.HybridSystem, ::AbstractHybridFormulation) = false

PSI.sos_status(::PSY.HybridSystem, ::AbstractHybridFormulation) =
    PSI.SOSStatusVariable.VARIABLE

function PSI.add_proportional_cost!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::U,
    ::W,
) where {
    T <: ThermalStatus,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    multiplier = PSI.objective_function_multiplier(T(), W())
    for d in devices
        op_cost_data = PSY.get_operation_cost(PSY.get_storage(d))
        isnothing(op_cost_data) && continue
        cost_term = PSI.proportional_cost(op_cost_data, T(), d, W())
        iszero(cost_term) && continue
        for t in PSI.get_time_steps(container)
            PSI._add_proportional_term!(container, T(), d, cost_term * multiplier, t)
        end
    end
    return
end

function PSI.add_variable_cost!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::U,
    ::W,
) where {
    T <: ThermalPower,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    for d in devices
        op_cost_data = PSY.get_operation_cost(PSY.get_thermal_unit(d))
        variable_cost_data = PSI.variable_cost(op_cost_data, T(), d, W())
        PSI._add_variable_cost_to_objective!(container, T(), d, variable_cost_data, W())
    end
    return
end

############### Renewable costs, HybridSystem #######################

PSI.objective_function_multiplier(::RenewablePower, ::AbstractHybridFormulation) =
    PSI.OBJECTIVE_FUNCTION_NEGATIVE
PSI.variable_cost(
    cost::PSY.OperationalCost,
    ::RenewablePower,
    ::PSY.HybridSystem,
    U::AbstractHybridFormulation,
) = PSY.get_variable(cost)

function PSI.add_variable_cost!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::U,
    ::W,
) where {
    T <: RenewablePower,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    for d in devices
        op_cost_data = PSY.get_operation_cost(PSY.get_renewable_unit(d))
        PSI._add_variable_cost_to_objective!(container, T(), d, op_cost_data, W())
    end
    return
end
############### Objective Function, HybridSystem #######################

function PSI.objective_function!(
    container::PSI.OptimizationContainer,
    devices::U,
    ::PSI.DeviceModel{D, W},
    ::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    # Filter Devices
    _hybrids_with_thermal = [d for d in devices if PSY.get_thermal_unit(d) !== nothing]
    _hybrids_with_storage = [d for d in devices if PSY.get_storage(d) !== nothing]
    _hybrids_with_renewable = [d for d in devices if PSY.get_renewable_unit(d) !== nothing]

    # Add Storage Cost
    if !isempty(_hybrids_with_storage)
        PSI.add_proportional_cost!(container, BatteryCharge(), _hybrids_with_storage, W())
        PSI.add_proportional_cost!(
            container,
            BatteryDischarge(),
            _hybrids_with_storage,
            W(),
        )
    end
    # Add Thermal Cost
    if !isempty(_hybrids_with_thermal)
        PSI.add_variable_cost!(container, ThermalPower(), _hybrids_with_thermal, W())
        PSI.add_proportional_cost!(container, ThermalStatus(), _hybrids_with_thermal, W())
    end

    # Add Renewable Cost
    if !isempty(_hybrids_with_renewable)
        PSI.add_variable_cost!(container, RenewablePower(), _hybrids_with_renewable, W())
    end
    return
end

###################################################################
######################### Variables ###############################
###################################################################

# Uses PSI calls except for component with reserves

# Reserve variable function for components
function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{W},
    devices::Union{Vector{U}, IS.FlattenIteratorWrapper{U}},
    formulation::V,
) where {
    U <: PSY.HybridSystem,
    W <: Union{ComponentReserveVariableType, ReserveVariableOut, ReserveVariableIn},
    V <: Union{HybridDispatchWithReserves, MerchantModelWithReserves},
}
    time_steps = PSI.get_time_steps(container)
    # TODO
    # Best way to create this variable? We need to have all services and its type.
    services = Set()
    for d in devices
        union!(services, PSY.get_services(d))
    end

    for service in services
        variable = PSI.add_variable_container!(
            container,
            W(),
            typeof(service),
            PSY.get_name.(devices),
            time_steps;
            meta=PSY.get_name(service),
        )

        for d in devices, t in time_steps
            name = PSY.get_name(d)
            variable[name, t] = JuMP.@variable(
                PSI.get_jump_model(container),
                base_name = "$(W)_$(PSY.get_name(service))_{$(PSY.get_name(d)), $(t)}",
                lower_bound = 0.0
            )
        end
    end

    return
end

###################################################################
######################## Parameters ###############################
###################################################################

# Uses PSI calls

###################################################################
####################### Expressions ###############################
###################################################################

# Uses PSI calls except for reserve Expressions

###################################################################
######################## Initial Conditions #######################
###################################################################

function PSI.initial_conditions!(
    container::PSI.OptimizationContainer,
    devices::Vector{D},
    formulation::AbstractHybridFormulation,
) where {D <: PSY.HybridSystem}
    PSI.add_initial_condition!(container, devices, formulation, PSI.InitialEnergyLevel())
    return
end

###################################################################
####################### Constraints ###############################
###################################################################

############ Total Power Constraints, HybridSystem ################

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:PSI.PowerVariableLimitsConstraint},
    U::Type{<:Union{PSI.ActivePowerInVariable, PSI.ActivePowerOutVariable}},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    network_model::PSI.NetworkModel{X},
) where {V <: PSY.HybridSystem, W <: AbstractHybridFormulation, X <: PM.AbstractPowerModel}
    PSI.add_range_constraints!(container, T, U, devices, model, X)
    return
end

############ Output/Input Constraints, HybridSystem ################

# Status Out ON (Generation Operation)
function _add_constraints_statusout!(
    container::PSI.OptimizationContainer,
    T::Type{<:StatusOutOn},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, PSI.ReservationVariable(), D)
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")

    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        max_limit = PSI.get_variable_upper_bound(PSI.ActivePowerOutVariable(), device, W())
        @assert max_limit !== nothing ci_name
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_out[ci_name, t] <= max_limit * varon[ci_name, t]
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:StatusOutOn},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    _add_constraints_statusout!(container, T, devices, W())
    return
end

# Status Out ON (Generation Operation) With Reserves
function _add_constraints_statusout_withreserves!(
    container::PSI.OptimizationContainer,
    T::Type{<:StatusOutOn},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, PSI.ReservationVariable(), D)
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), D)
    res_out_up = PSI.get_expression(container, TotalReserveOutUpExpression(), D)
    res_out_down = PSI.get_expression(container, TotalReserveOutDownExpression(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")
    con_lb = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="lb")

    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        max_limit = PSI.get_variable_upper_bound(PSI.ActivePowerOutVariable(), device, W())
        @assert max_limit !== nothing ci_name
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_out[ci_name, t] + res_out_up[ci_name, t] <= max_limit * varon[ci_name, t]
        )
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_out[ci_name, t] - res_out_down[ci_name, t] >= 0.0
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:StatusOutOn},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: HybridDispatchWithReserves,
} where {D <: PSY.HybridSystem}
    _add_constraints_statusout_withreserves!(container, T, devices, W())
    return
end

# Status In ON (Demand Operation)
function _add_constraints_statusin!(
    container::PSI.OptimizationContainer,
    T::Type{<:StatusInOn},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, PSI.ReservationVariable(), D)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")

    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        max_limit = PSI.get_variable_upper_bound(PSI.ActivePowerInVariable(), device, W())
        @assert max_limit !== nothing ci_name
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_in[ci_name, t] <= max_limit * (1.0 - varon[ci_name, t])
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:StatusInOn},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    _add_constraints_statusin!(container, T, devices, W())
    return
end

# Status In ON (Demand Operation) with Reserves
function _add_constraints_statusin_withreserves!(
    container::PSI.OptimizationContainer,
    T::Type{<:StatusInOn},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, PSI.ReservationVariable(), D)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), D)
    res_in_up = PSI.get_expression(container, TotalReserveInUpExpression(), D)
    res_in_down = PSI.get_expression(container, TotalReserveInDownExpression(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")
    con_lb = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="lb")

    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        max_limit = PSI.get_variable_upper_bound(PSI.ActivePowerInVariable(), device, W())
        @assert max_limit !== nothing ci_name
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_in[ci_name, t] + res_in_down[ci_name, t] <=
            max_limit * (1.0 - varon[ci_name, t])
        )
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_in[ci_name, t] - res_in_up[ci_name, t] >= 0.0
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:StatusInOn},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: HybridDispatchWithReserves,
} where {D <: PSY.HybridSystem}
    _add_constraints_statusin_withreserves!(container, T, devices, W())
    return
end

############ Asset Balance Constraints, HybridSystem ###############
const JUMP_SET_TYPE = JuMP.Containers.DenseAxisArray{
    JuMP.VariableRef,
    1,
    Tuple{UnitRange{Int64}},
    Tuple{JuMP.Containers._AxisLookup{Tuple{Int64, Int64}}},
}

function _add_constrains_energyassetbalance!(
    container::PSI.OptimizationContainer,
    T::Type{<:EnergyAssetBalance},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), D)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), D)
    con_bal = PSI.add_constraints_container!(container, T(), D, names, time_steps)

    for device in devices
        ci_name = PSY.get_name(device)
        vars_pos = Set{JUMP_SET_TYPE}()
        vars_neg = Set{JUMP_SET_TYPE}()
        load_set = Set()

        if !isnothing(PSY.get_thermal_unit(device))
            p_th = PSI.get_variable(container, ThermalPower(), D)
            push!(vars_pos, p_th[ci_name, :])
        end
        if !isnothing(PSY.get_renewable_unit(device))
            p_re = PSI.get_variable(container, RenewablePower(), D)
            push!(vars_pos, p_re[ci_name, :])
        end
        if !isnothing(PSY.get_storage(device))
            p_ch = PSI.get_variable(container, BatteryCharge(), D)
            p_ds = PSI.get_variable(container, BatteryDischarge(), D)
            push!(vars_pos, p_ds[ci_name, :])
            push!(vars_neg, p_ch[ci_name, :])
        end
        if !isnothing(PSY.get_electric_load(device))
            P = ElectricLoadTimeSeries
            param_container = PSI.get_parameter(container, P(), D)
            param = PSI.get_parameter_column_refs(param_container, ci_name).data
            multiplier = PSY.get_max_active_power(PSY.get_electric_load(device))
            push!(load_set, param * multiplier)
        end
        for t in time_steps
            total_power = -p_out[ci_name, t] + p_in[ci_name, t]
            for vp in vars_pos
                JuMP.add_to_expression!(total_power, vp[t])
            end
            for vn in vars_neg
                JuMP.add_to_expression!(total_power, -vn[t])
            end
            for load in load_set
                JuMP.add_to_expression!(total_power, -load[t])
            end
            con_bal[ci_name, t] =
                JuMP.@constraint(PSI.get_jump_model(container), total_power == 0.0)
        end
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:EnergyAssetBalance},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    _add_constrains_energyassetbalance!(container, T, devices, W())
    return
end

############## Thermal Constraints, HybridSystem ###################

# ThermalOn Variable ON
function _add_constraints_thermalon_variableon!(
    container::PSI.OptimizationContainer,
    T::Type{<:ThermalOnVariableOn},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, ThermalStatus(), D)
    p_th = PSI.get_variable(container, ThermalPower(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")

    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        max_limit = PSY.get_active_power_limits(PSY.get_thermal_unit(device)).max
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_th[ci_name, t] <= max_limit * varon[ci_name, t]
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:ThermalOnVariableOn},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    _add_constraints_thermalon_variableon!(container, T, devices, W())
    return
end

# ThermalOn Variable OFF
function _add_constraints_thermalon_variableoff!(
    container::PSI.OptimizationContainer,
    T::Type{<:ThermalOnVariableOff},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, ThermalStatus(), D)
    p_th = PSI.get_variable(container, ThermalPower(), D)
    con_lb = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="lb")

    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        min_limit = PSY.get_active_power_limits(PSY.get_thermal_unit(device)).min
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            min_limit * varon[ci_name, t] <= p_th[ci_name, t]
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:ThermalOnVariableOff},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    _add_constraints_thermalon_variableoff!(container, T, devices, W())
    return
end

############## Storage Constraints, HybridSystem ###################

#BatteryStatus Charge ON
function _add_constraints_batterychargeon!(
    container::PSI.OptimizationContainer,
    T::Type{<:BatteryStatusChargeOn},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    status_st = PSI.get_variable(container, BatteryStatus(), D)
    p_ch = PSI.get_variable(container, BatteryCharge(), D)
    con_ub_ch =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")

    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        max_limit = PSY.get_input_active_power_limits(PSY.get_storage(device)).max
        con_ub_ch[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_ch[ci_name, t] <= (1.0 - status_st[ci_name, t]) * max_limit
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:BatteryStatusChargeOn},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    _add_constraints_batterychargeon!(container, T, devices, W())
    return
end

# BatteryStatus Discharge ON
function _add_constraints_batterydischargeon!(
    container::PSI.OptimizationContainer,
    T::Type{<:BatteryStatusDischargeOn},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    status_st = PSI.get_variable(container, BatteryStatus(), D)
    p_ds = PSI.get_variable(container, BatteryDischarge(), D)
    con_ub_ds =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")

    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        max_limit = PSY.get_output_active_power_limits(PSY.get_storage(device)).max
        con_ub_ds[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_ds[ci_name, t] <= status_st[ci_name, t] * max_limit
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:BatteryStatusDischargeOn},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    _add_constraints_batterydischargeon!(container, T, devices, W())
    return
end

# Battery Balance
function _add_constraints_batterybalance!(
    container::PSI.OptimizationContainer,
    T::Type{<:BatteryBalance},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    names = [PSY.get_name(d) for d in devices]
    energy_var = PSI.get_variable(container, PSI.EnergyVariable(), D)
    charge_var = PSI.get_variable(container, BatteryCharge(), D)
    discharge_var = PSI.get_variable(container, BatteryDischarge(), D)
    con_soc = PSI.add_constraints_container!(container, T(), D, names, time_steps)
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), D)

    for ic in initial_conditions
        device = PSI.get_component(ic)
        ci_name = PSY.get_name(device)
        storage = PSY.get_storage(device)
        efficiency = PSY.get_efficiency(storage)
        con_soc[ci_name, 1] = JuMP.@constraint(
            PSI.get_jump_model(container),
            energy_var[ci_name, 1] ==
            PSI.get_value(ic) +
            fraction_of_hour * (
                charge_var[ci_name, 1] * efficiency.in -
                (discharge_var[ci_name, 1] / efficiency.out)
            )
        )

        for t in time_steps[2:end]
            con_soc[ci_name, t] = JuMP.@constraint(
                PSI.get_jump_model(container),
                energy_var[ci_name, t] ==
                energy_var[ci_name, t - 1] +
                fraction_of_hour * (
                    charge_var[ci_name, t] * efficiency.in -
                    (discharge_var[ci_name, t] / efficiency.out)
                )
            )
        end
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:BatteryBalance},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    _add_constraints_batterybalance!(container, T, devices, W())
    return
end

# Cycling Charge
function _add_constraints_cyclingcharge!(
    container::PSI.OptimizationContainer,
    T::Type{<:CyclingCharge},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    cycles_in_horizon =
        CYCLES_PER_DAY * fraction_of_hour * length(time_steps) / HOURS_IN_DAY
    names = [PSY.get_name(d) for d in devices]
    charge_var = PSI.get_variable(container, BatteryCharge(), D)
    con_cycling_ch = PSI.add_constraints_container!(container, T(), D, names)
    for device in devices
        ci_name = PSY.get_name(device)
        storage = PSY.get_storage(device)
        efficiency = PSY.get_efficiency(storage)
        E_max = PSY.get_state_of_charge_limits(storage).max
        con_cycling_ch[ci_name] = JuMP.@constraint(
            PSI.get_jump_model(container),
            efficiency.in * fraction_of_hour * sum(charge_var[ci_name, :]) <=
            cycles_in_horizon * E_max
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:CyclingCharge},
    devices::U,
    model::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    if PSI.get_attribute(model, "cycling")
        _add_constraints_cyclingcharge!(container, T, devices, W())
    end
    return
end

# Cycling Discharge
function _add_constraints_cyclingdischarge!(
    container::PSI.OptimizationContainer,
    T::Type{<:CyclingDischarge},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    cycles_in_horizon =
        CYCLES_PER_DAY * fraction_of_hour * length(time_steps) / HOURS_IN_DAY
    names = [PSY.get_name(d) for d in devices]
    discharge_var = PSI.get_variable(container, BatteryDischarge(), D)
    con_cycling_ds = PSI.add_constraints_container!(container, T(), D, names)
    for device in devices
        ci_name = PSY.get_name(device)
        storage = PSY.get_storage(device)
        efficiency = PSY.get_efficiency(storage)
        E_max = PSY.get_state_of_charge_limits(storage).max
        con_cycling_ds[ci_name] = JuMP.@constraint(
            PSI.get_jump_model(container),
            (1.0 / efficiency.out) * fraction_of_hour * sum(discharge_var[ci_name, :]) <= cycles_in_horizon * E_max
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:CyclingDischarge},
    devices::U,
    model::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    if PSI.get_attribute(model, "cycling")
        _add_constraints_cyclingdischarge!(container, T, devices, W())
    end
    return
end

############## Renewable Constraints, HybridSystem ###################

function _add_constraints_renewablelimit!(
    container::PSI.OptimizationContainer,
    T::Type{<:RenewableActivePowerLimitConstraint},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    P = RenewablePowerTimeSeries
    p_re = PSI.get_variable(container, RenewablePower(), D)
    names = [PSY.get_name(d) for d in devices]
    con_ub_re =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")
    param_container = PSI.get_parameter(container, P(), D)
    for device in devices
        ci_name = PSY.get_name(device)
        multiplier = PSY.get_max_active_power(device.renewable_unit)
        param = PSI.get_parameter_column_refs(param_container, ci_name)
        for t in time_steps
            con_ub_re[ci_name, t] = JuMP.@constraint(
                container.JuMPmodel,
                p_re[ci_name, t] <= multiplier * param[t]
            )
        end
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:RenewableActivePowerLimitConstraint},
    devices::U,
    model::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    _add_constraints_renewablelimit!(container, T, devices, W())
    return
end

############## Thermal Constraints ReserveLimit, HybridSystem ###################

function _add_thermallimit_withreserves!(
    container::PSI.OptimizationContainer,
    T::Type{<:ThermalReserveLimit},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, ThermalStatus(), D)
    p_th = PSI.get_variable(container, ThermalPower(), D)
    reg_th_up = PSI.get_expression(container, ThermalReserveUpExpression(), D)
    reg_th_dn = PSI.get_expression(container, ThermalReserveDownExpression(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")
    con_lb = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="lb")

    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        min_limit, max_limit = PSY.get_active_power_limits(PSY.get_thermal_unit(device))
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_th[ci_name, t] + reg_th_up[ci_name, t] <= max_limit * varon[ci_name, t]
        )
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_th[ci_name, t] - reg_th_dn[ci_name, t] >= min_limit * varon[ci_name, t]
        )
    end
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:ThermalReserveLimit},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: HybridDispatchWithReserves,
} where {D <: PSY.HybridSystem}
    _add_thermallimit_withreserves!(container, T, devices, W())
    return
end

############## Storage Constraints ReserveLimit, HybridSystem ###################

# Range Constraint Coverage Discharge
function _add_constraints_reservecoverage_withreserves!(
    container::PSI.OptimizationContainer,
    T::Type{<:ReserveCoverageConstraint},
    devices::U,
    service::V,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    V <: PSY.Reserve{PSY.ReserveUp},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    num_periods =
        Dates.value(Dates.Minute(PSY.get_sustained_time(service))) /
        Dates.value(Dates.Minute(resolution))
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), D)
    energy_var = PSI.get_variable(container, PSI.EnergyVariable(), D)
    service_name = PSY.get_name(service)
    reserve_var = PSI.get_variable(container, DischargingReserveVariable(), V, service_name)
    names = [PSY.get_name(d) for d in devices]
    con = PSI.add_constraints_container!(
        container,
        T(),
        D,
        names,
        time_steps,
        meta=service_name,
    )
    for ic in initial_conditions
        device = PSI.get_component(ic)
        # TODO FIX: This assert will trigger if we have a hybrid that does not participate in a specific service but others do
        @assert service in PSY.get_services(device)
        ci_name = PSY.get_name(device)
        storage = PSY.get_storage(device)
        inv_efficiency = 1.0 / PSY.get_efficiency(storage).out
        sustained_param = inv_efficiency * fraction_of_hour * num_periods
        con[ci_name, 1] = JuMP.@constraint(
            container.JuMPmodel,
            sustained_param * reserve_var[ci_name, 1] <= PSI.get_value(ic)
        )
        for t in time_steps[2:end]
            con[ci_name, t] = JuMP.@constraint(
                container.JuMPmodel,
                sustained_param * reserve_var[ci_name, t] <= energy_var[ci_name, t - 1]
            )
        end
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ReserveCoverageConstraint},
    devices::U,
    service::V,
    model::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    V <: PSY.Reserve{PSY.ReserveUp},
    W <: HybridDispatchWithReserves,
} where {D <: PSY.HybridSystem}
    _add_constraints_reservecoverage_withreserves!(container, T, devices, service, W())
    return
end

# Range Constraint Coverage Discharge
function _add_constraints_reservecoverage_withreserves!(
    container::PSI.OptimizationContainer,
    T::Type{<:ReserveCoverageConstraint},
    devices::U,
    service::V,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    V <: PSY.Reserve{PSY.ReserveDown},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    sustained_time = PSY.get_sustained_time(service) # in seconds
    num_periods = sustained_time / Dates.value(Dates.Second(resolution))
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), D)
    energy_var = PSI.get_variable(container, PSI.EnergyVariable(), D)
    service_name = PSY.get_name(service)
    reserve_var = PSI.get_variable(container, ChargingReserveVariable(), V, service_name)
    names = [PSY.get_name(d) for d in devices]
    con = PSI.add_constraints_container!(
        container,
        T(),
        D,
        names,
        time_steps,
        meta=service_name,
    )
    for ic in initial_conditions
        device = PSI.get_component(ic)
        # TODO FIX: This assert will trigger if we have a hybrid that does not participate in a specific service but others do
        @assert service in PSY.get_services(device)
        ci_name = PSY.get_name(device)
        storage = PSY.get_storage(device)
        efficiency = PSY.get_efficiency(storage).in
        E_max = PSY.get_state_of_charge_limits(storage).max
        sustained_param = efficiency * num_periods * fraction_of_hour
        con[ci_name, 1] = JuMP.@constraint(
            container.JuMPmodel,
            sustained_param * reserve_var[ci_name, 1] <= E_max - PSI.get_value(ic)
        )
        for t in time_steps[2:end]
            con[ci_name, t] = JuMP.@constraint(
                container.JuMPmodel,
                sustained_param * reserve_var[ci_name, t] <=
                E_max - energy_var[ci_name, t - 1]
            )
        end
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ReserveCoverageConstraint},
    devices::U,
    service::V,
    model::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    V <: PSY.Reserve{PSY.ReserveDown},
    W <: HybridDispatchWithReserves,
} where {D <: PSY.HybridSystem}
    _add_constraints_reservecoverage_withreserves!(container, T, devices, service, W())
    return
end

# Charge Upper/Lower Reserve Limits
function _add_constraints_charging_reservelimit!(
    container::PSI.OptimizationContainer,
    T::Type{<:ChargingReservePowerLimit},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    status_st = PSI.get_variable(container, BatteryStatus(), D)
    p_ch = PSI.get_variable(container, BatteryCharge(), D)
    reg_ch_up = PSI.get_expression(container, ChargeReserveUpExpression(), D)
    reg_ch_dn = PSI.get_expression(container, ChargeReserveDownExpression(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")
    con_lb = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="lb")

    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        max_limit = PSY.get_input_active_power_limits(PSY.get_storage(device)).max
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_ch[ci_name, t] + reg_ch_dn[ci_name, t] <=
            max_limit * (1.0 - status_st[ci_name, t])
        )
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_ch[ci_name, t] - reg_ch_up[ci_name, t] >= 0.0
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:ChargingReservePowerLimit},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: HybridDispatchWithReserves,
} where {D <: PSY.HybridSystem}
    _add_constraints_charging_reservelimit!(container, T, devices, W())
    return
end

# Discharge Upper/Lower Reserve Limit
function _add_constraints_discharging_reservelimit!(
    container::PSI.OptimizationContainer,
    T::Type{<:DischargingReservePowerLimit},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    status_st = PSI.get_variable(container, BatteryStatus(), D)
    p_ds = PSI.get_variable(container, BatteryDischarge(), D)
    reg_ds_up = PSI.get_expression(container, DischargeReserveUpExpression(), D)
    reg_ds_dn = PSI.get_expression(container, DischargeReserveDownExpression(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")
    con_lb = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="lb")

    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        max_limit = PSY.get_input_active_power_limits(PSY.get_storage(device)).max
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_ds[ci_name, t] + reg_ds_up[ci_name, t] <= max_limit * status_st[ci_name, t]
        )
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_ds[ci_name, t] - reg_ds_dn[ci_name, t] >= 0.0
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:DischargingReservePowerLimit},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: HybridDispatchWithReserves,
} where {D <: PSY.HybridSystem}
    _add_constraints_discharging_reservelimit!(container, T, devices, W())
end

############## Renewable Constraints ReserveLimit, HybridSystem ###################

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:RenewableReserveLimit},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: HybridDispatchWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    P = RenewablePowerTimeSeries
    names = [PSY.get_name(d) for d in devices]
    p_re = PSI.get_variable(container, RenewablePower(), D)
    reg_re_up = PSI.get_expression(container, RenewableReserveUpExpression(), D)
    reg_re_dn = PSI.get_expression(container, RenewableReserveDownExpression(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")
    con_lb = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="lb")
    param_container = PSI.get_parameter(container, P(), D)
    for device in devices
        ci_name = PSY.get_name(device)
        multiplier = PSY.get_max_active_power(device.renewable_unit)
        param = PSI.get_parameter_column_refs(param_container, ci_name)
        for t in time_steps
            con_ub[ci_name, t] = JuMP.@constraint(
                PSI.get_jump_model(container),
                p_re[ci_name, t] + reg_re_up[ci_name, t] <= multiplier * param[t]
            )
            con_lb[ci_name, t] = JuMP.@constraint(
                PSI.get_jump_model(container),
                p_re[ci_name, t] - reg_re_dn[ci_name, t] >= 0.0
            )
        end
    end
    return
end

############## Reserve Balance and Output Constraints, HybridSystem ###################

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{AuxiliaryReserveConstraint},
    devices::U,
    service::V,
    model::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    V <: PSY.Reserve,
    W <: HybridDispatchWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    service_name = PSY.get_name(service)
    res_out = PSI.get_variable(container, ReserveVariableOut(), V, service_name)
    res_in = PSI.get_variable(container, ReserveVariableIn(), V, service_name)
    res_var = PSI.get_variable(container, PSI.ActivePowerReserveVariable(), V, service_name)
    names = [PSY.get_name(d) for d in devices]
    con = PSI.add_constraints_container!(
        container,
        T(),
        D,
        names,
        time_steps,
        meta=service_name,
    )
    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        con[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            res_out[ci_name, t] + res_in[ci_name, t] == res_var[ci_name, t]
        )
    end
    return
end

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ReserveBalance},
    devices::U,
    service::V,
    model::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    V <: PSY.Reserve,
    W <: HybridDispatchWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    service_name = PSY.get_name(service)
    res_out = PSI.get_variable(container, ReserveVariableOut(), V, service_name)
    res_in = PSI.get_variable(container, ReserveVariableIn(), V, service_name)
    names = [PSY.get_name(d) for d in devices]
    con = PSI.add_constraints_container!(
        container,
        T(),
        D,
        names,
        time_steps,
        meta=service_name,
    )
    for device in devices
        ci_name = PSY.get_name(device)
        vars_pos = Set{JUMP_SET_TYPE}()

        if !isnothing(PSY.get_thermal_unit(device))
            res_th = PSI.get_variable(container, ThermalReserveVariable(), V, service_name)
            push!(vars_pos, res_th[ci_name, :])
        end
        if !isnothing(PSY.get_renewable_unit(device))
            res_re =
                PSI.get_variable(container, RenewableReserveVariable(), V, service_name)
            push!(vars_pos, res_re[ci_name, :])
        end
        if !isnothing(PSY.get_storage(device))
            res_ch = PSI.get_variable(container, ChargingReserveVariable(), V, service_name)
            res_ds =
                PSI.get_variable(container, DischargingReserveVariable(), V, service_name)
            push!(vars_pos, res_ds[ci_name, :])
            push!(vars_pos, res_ch[ci_name, :])
        end
        for t in time_steps
            total_reserve = -res_out[ci_name, t] - res_in[ci_name, t]
            for vp in vars_pos
                JuMP.add_to_expression!(total_reserve, vp[t])
            end
            con[ci_name, t] =
                JuMP.@constraint(PSI.get_jump_model(container), total_reserve == 0.0)
        end
    end
    return
end
