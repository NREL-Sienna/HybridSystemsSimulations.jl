function PSI.get_default_time_series_names(
    ::Type{PSY.HybridSystem},
    ::Type{<:Union{PSI.FixedOutput, AbstractHybridFormulation}},
)
    return Dict{Type{<:PSI.TimeSeriesParameter}, String}(
        ActivePowerTimeSeriesParameter => "max_active_power",
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

#### Asset Variables ###
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
    ::BatteryStateOfCharge,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_binary(
    ::BatteryStatus,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = true

# Warm Start TODO

###################################################################
######################### Variables ###############################
###################################################################

############### Asset Variables, HybridSystem #####################

function _add_variable!(
    container::PSI.OptimizationContainer,
    ::T,
    devices::U,
    formulation::AbstractHybridFormulation,
) where {
    T <: HybridAssetVariableType,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
} where {D <: PSY.HybridSystem}
    @assert !isempty(devices)
    time_steps = get_time_steps(container)
    settings = get_settings(container)
    binary = get_variable_binary(T(), D, formulation)

    for d in devices
        for t in time_steps
            name = PSY.get_name(d)
            variable[(name, t)] = JuMP.@variable(
                get_jump_model(container),
                base_name = "$(T)_$(D)_{$(name), $(t)}",
                binary = binary
            )

            ub = get_variable_upper_bound(T(), d, formulation)
            ub !== nothing && JuMP.set_upper_bound(variable[name, subcomp_key, t], ub)

            lb = get_variable_lower_bound(T(), d, formulation)
            lb !== nothing &&
                !binary &&
                JuMP.set_lower_bound(variable[name, subcomp_key, t], lb)

            if get_warm_start(settings)
                init = get_variable_warm_start_value(T(), d, formulation)
                init !== nothing &&
                    JuMP.set_start_value(variable[name, subcomp_key, t], init)
            end
        end
    end

    return
end

function add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::Union{Vector{U}, IS.FlattenIteratorWrapper{U}},
    formulation::AbstractHybridFormulation,
) where {
    T <: HybridAssetVariableType,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
} where {D <: PSY.HybridSystem}
    _add_variable!(container, T(), devices, formulation)
    return
end

###################################################################
######################## Parameters ###############################
###################################################################

#function PSI.get_default_time_series_names(
#    ::Type{<:PSY.HybridSystem},
#    ::Type{<:Union{PSI.FixedOutput, HybridEnergyOnlyDispatch}},
#)
#    return Dict{Type{<:TimeSeriesParameter}, String}(
#        RenewablePowerTimeSeries => "RenewableDispatch__max_active_power",
#        ElectricLoadTimeSeries => "PowerLoad__max_active_power",
#    )
#end

function PSI.add_parameters!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::U,
    model::PSI.DeviceModel{D, W},
) where {
    T <: RenewablePowerTimeSeries,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    if get_rebuild_model(get_settings(container)) && has_container_key(container, T, D)
        return
    end
    _devices = [d for d in devices if PSY.get_renewable_unit(d) !== nothing]
    add_parameters!(container, T(), _devices, model)
    return
end

function PSI.add_parameters!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::U,
    model::PSI.DeviceModel{D, W},
) where {
    T <: ElectricLoadTimeSeries,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    if get_rebuild_model(get_settings(container)) && has_container_key(container, T, D)
        return
    end
    _devices = [d for d in devices if PSY.get_electric_load(d) !== nothing]
    add_parameters!(container, T(), _devices, model)
    return
end

###################################################################
####################### Constraints ###############################
###################################################################

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:PSI.PowerVariableLimitsConstraint},
    U::Type{<:Union{PSI.ActivePowerInVariable, PSI.ActivePowerOutVariable}},
    devices::IS.FlattenIteratorWrapper{V},
    model::PSI.DeviceModel{V, W},
    X::Type{<:PM.AbstractPowerModel},
) where {V <: PSY.HybridSystem, W <: AbstractHybridFormulation}
    PSI.add_range_constraints!(container, T, U, devices, model, X)
    return
end

############## Thermal Constraints, HybridSystem ###################

function PSI.add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:ThermalOnVariableOn},
    devices::U,
    ::PSI.DeviceModel{D, W},
    X::Type{<:PM.AbstractPowerModel},
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
            container.JuMPmodel,
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
    X::Type{<:PM.AbstractPowerModel},
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
            container.JuMPmodel,
            min_limit * varon[ci_name, t] <= p_th[ci_name, t]
        )
    end
    return
end
