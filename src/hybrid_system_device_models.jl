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

PSI.objective_function_multiplier(
    ::RenewablePower,
    ::AbstractHybridFormulation,
) = PSI.OBJECTIVE_FUNCTION_NEGATIVE
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
    return
end

###################################################################
######################### Variables ###############################
###################################################################

# Uses PSI calls

###################################################################
######################## Parameters ###############################
###################################################################

# Uses PSI calls

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
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, PSI.ReservationVariable(), D)
    p_out = PSI.get_variable(container, ActivePowerOutVariable(), D)
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
    T::Type{<:StatusInOn},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, PSI.ReservationVariable(), D)
    p_in = PSI.get_variable(container, ActivePowerInVariable(), D)
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

############ Asset Balance Constraints, HybridSystem ###############
const JUMP_SET_TYPE = JuMP.Containers.DenseAxisArray{JuMP.VariableRef, 1, Tuple{UnitRange{Int64}}, Tuple{JuMP.Containers._AxisLookup{Tuple{Int64, Int64}}}}
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
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), D)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), D)
    con_bal = PSI.add_constraints_container!(container, T(), D, names, time_steps)

    for device in devices
        ci_name = PSY.get_name(device)
        vars_pos = Set{JUMP_SET_TYPE}()
        vars_neg = Set{JUMP_SET_TYPE}()

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
            parameter_values = PSI.get_parameter_values(param_container)
            multiplier = PSI.get_parameter_multiplier_array(container, P(), D)
            push!(vars_neg, parameter_values[ci_name, :] .* multiplier[ci_name, :])
        end

        for t in time_steps
            total_power = -p_out[ci_name, t] + p_in[ci_name, t]
            for vp in vars_pos
                JuMP.add_to_expression!(total_power, vp[t])
            end
            for vn in vars_neg
                JuMP.add_to_expression!(total_power, -vn[t])
            end
            con_bal[ci_name, t] =
                JuMP.@constraint(PSI.get_jump_model(container), total_power == 0.0)
        end
    end
    return
end

############## Thermal Constraints, HybridSystem ###################

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
    T::Type{<:ThermalOnVariableOff},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
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

############## Storage Constraints, HybridSystem ###################

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
    T::Type{<:BatteryStatusDischargeOn},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
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
    T::Type{<:BatteryBalance},
    devices::U,
    ::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
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
    T::Type{<:CyclingCharge},
    devices::U,
    model::PSI.DeviceModel{D, W},
    network_model::PSI.NetworkModel{<:PM.AbstractPowerModel},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    if PSI.get_attribute(model, "cycling")
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
                (1.0 / efficiency.out) *
                fraction_of_hour *
                sum(discharge_var[ci_name, :]) <= cycles_in_horizon * E_max
            )
        end
    end
    return
end

############## Renewable Constraints, HybridSystem ###################

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
    time_steps = PSI.get_time_steps(container)
    P = RenewablePowerTimeSeries
    p_re = PSI.get_variable(container, RenewablePower(), D)
    names = [PSY.get_name(d) for d in devices]
    con_ub_re =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")
    param_container = PSI.get_parameter(container, P(), D)
    parameter_values = PSI.get_parameter_values(param_container)
    multiplier = PSI.get_parameter_multiplier_array(container, P(), D)
    for device in devices, t in time_steps
        ci_name = PSY.get_name(device)
        con_ub_re[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_re[ci_name, t] <= multiplier[ci_name, t] * parameter_values[ci_name, t]
        )
    end
end
