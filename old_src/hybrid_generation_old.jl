#! format: off
requires_initialization(::AbstractHybridFormulation) = false

get_variable_multiplier(::PSI.ActivePowerOutVariable, ::Type{<:PSY.HybridSystem}, ::AbstractHybridFormulation) = 1.0
get_variable_multiplier(::PSI.ActivePowerInVariable, ::Type{<:PSY.HybridSystem}, ::AbstractHybridFormulation) = -1.0
get_expression_type_for_reserve(::ActivePowerReserveVariable, ::Type{<:PSY.HybridSystem}, ::Type{<:PSY.Reserve{PSY.ReserveUp}}) = ComponentReserveUpBalanceExpression
get_expression_type_for_reserve(::ActivePowerReserveVariable, ::Type{<:PSY.HybridSystem}, ::Type{<:PSY.Reserve{PSY.ReserveDown}}) = ComponentReserveDownBalanceExpression

########################### PSI.ActivePowerOutVariable, HybridSystem #################################
get_variable_binary(::ActivePowerVariable, ::Type{PSY.HybridSystem}, ::AbstractHybridFormulation) = false
get_variable_warm_start_value(::ActivePowerVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_active_power(d)
get_variable_lower_bound(::ActivePowerVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = -1.0 * PSY.get_input_active_power_limits(d).max
get_variable_lower_bound(::ActivePowerVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_output_active_power_limits(d).min
get_variable_upper_bound(::ActivePowerVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_output_active_power_limits(d).max

############## ComponentOutputActivePowerVariable, HybridSystem ####################
# get_variable_binary(::ComponentInputActivePowerVariable, ::Type{PSY.HybridSystem}, ::AbstractHybridFormulation) = false
# get_variable_lower_bound(::ComponentInputActivePowerVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = 0.0
get_variable_binary(::ComponentOutputActivePowerVariable, ::Type{PSY.HybridSystem}, ::AbstractHybridFormulation) = false
get_variable_lower_bound(::ComponentOutputActivePowerVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = 0.0

############## PSI.ActivePowerInVariable, HybridSystem ####################
get_variable_binary(::PSI.ActivePowerInVariable, ::Type{PSY.HybridSystem}, ::AbstractHybridFormulation) = false
get_variable_lower_bound(::PSI.ActivePowerInVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_input_active_power_limits(d).min
get_variable_upper_bound(::PSI.ActivePowerInVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_input_active_power_limits(d).max

############## PSI.ActivePowerOutVariable, HybridSystem ####################
get_variable_binary(::PSI.ActivePowerOutVariable, ::Type{PSY.HybridSystem}, ::AbstractHybridFormulation) = false
get_variable_upper_bound(::PSI.ActivePowerOutVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_output_active_power_limits(d).max
get_variable_lower_bound(::PSI.ActivePowerOutVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_output_active_power_limits(d).min

############## EnergyVariable, HybridSystem ####################
get_variable_binary(::ComponentEnergyVariable, ::Type{PSY.HybridSystem}, ::AbstractHybridFormulation) = false
get_variable_upper_bound(::ComponentEnergyVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_state_of_charge_limits(PSY.get_storage(d)).max
get_variable_lower_bound(::ComponentEnergyVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_state_of_charge_limits(PSY.get_storage(d)).min
get_variable_warm_start_value(::ComponentEnergyVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_initial_energy(PSY.get_storage(d))

############## ReactivePowerVariable, HybridSystem ####################
get_variable_binary(::ReactivePowerVariable, ::Type{PSY.HybridSystem}, ::AbstractHybridFormulation) = false
get_variable_upper_bound(::ReactivePowerVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_reactive_power_limits(PSY.get_storage(d)).max
get_variable_lower_bound(::ReactivePowerVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_reactive_power_limits(PSY.get_storage(d)).min
get_variable_warm_start_value(::ReactivePowerVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_reactive_power(PSY.get_storage(d))

############## ComponentReactivePowerVariable, ThermalGen ####################
get_variable_binary(::ComponentReactivePowerVariable, ::Type{PSY.HybridSystem}, ::AbstractHybridFormulation) = false
get_variable_lower_bound(::ComponentReactivePowerVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = 0.0

############## ComponentActivePowerReserveUpVariable, HybridSystem ####################
get_variable_binary(::ComponentActivePowerReserveUpVariable, ::Type{<:PSY.HybridSystem}, ::AbstractHybridFormulation) = false
get_variable_lower_bound(::ComponentActivePowerReserveUpVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = 0.0

############## ComponentActivePowerReserveDownVariable, HybridSystem ####################
get_variable_binary(::ComponentActivePowerReserveDownVariable, ::Type{<:PSY.HybridSystem}, ::AbstractHybridFormulation) = false
get_variable_lower_bound(::ComponentActivePowerReserveDownVariable, d::PSY.HybridSystem, ::AbstractHybridFormulation) = 0.0

############## PSI.ReservationVariable, HybridSystem ####################
get_variable_binary(::PSI.ReservationVariable, ::Type{<:PSY.HybridSystem}, ::AbstractHybridFormulation) = true
get_variable_binary(::ComponentPSI.ReservationVariable, ::Type{<:PSY.HybridSystem}, ::AbstractHybridFormulation) = true

#################### Initial Conditions for models ###############

initial_condition_default(::ComponentInitialEnergyLevel, d::PSY.HybridSystem, ::AbstractHybridFormulation) = PSY.get_initial_energy(PSY.get_storage(d))
initial_condition_variable(::ComponentInitialEnergyLevel, d::PSY.HybridSystem, ::AbstractHybridFormulation) = ComponentEnergyVariable()

########################Objective Function##################################################
objective_function_multiplier(::VariableType, ::AbstractHybridFormulation)=OBJECTIVE_FUNCTION_POSITIVE

proportional_cost(cost::PSY.OperationalCost, ::OnVariable, ::PSY.HybridSystem, ::AbstractHybridFormulation)=PSY.get_fixed(cost)
proportional_cost(cost::PSY.MarketBidCost, ::OnVariable, ::PSY.HybridSystem, ::AbstractHybridFormulation)=PSY.get_no_load(cost)

sos_status(::PSY.HybridSystem, ::AbstractHybridFormulation)=SOSStatusVariable.NO_VARIABLE

uses_compact_power(::PSY.HybridSystem, ::AbstractHybridFormulation)=false
variable_cost(cost::PSY.OperationalCost, ::PSY.HybridSystem, ::AbstractHybridFormulation)=PSY.get_variable(cost)

get_multiplier_value(::ActivePowerTimeSeriesParameter, d::PSY.HybridSystem, ::Type{<:PSY.RenewableGen}, ::AbstractHybridFormulation) = PSY.get_max_active_power(PSY.get_renewable_unit(d))
get_multiplier_value(::ActivePowerTimeSeriesParameter, d::PSY.HybridSystem, ::Type{<:PSY.ElectricLoad}, ::AbstractHybridFormulation) = PSY.get_max_active_power(PSY.get_electric_load(d))
#! format: on
get_initial_conditions_device_model(
    ::OperationModel,
    ::DeviceModel{T, <:AbstractHybridFormulation},
) where {T <: PSY.HybridSystem} = DeviceModel(T, HybridEnergyOnlyDispatchDisaptch)

does_subcomponent_exist(v::PSY.HybridSystem, ::Type{PSY.ThermalGen}) =
    !isnothing(PSY.get_thermal_unit(v))
does_subcomponent_exist(v::PSY.HybridSystem, ::Type{PSY.RenewableGen}) =
    !isnothing(PSY.get_renewable_unit(v))
does_subcomponent_exist(v::PSY.HybridSystem, ::Type{PSY.ElectricLoad}) =
    !isnothing(PSY.get_electric_load(v))
does_subcomponent_exist(v::PSY.HybridSystem, ::Type{PSY.Storage}) =
    !isnothing(PSY.get_storage(v))

get_subcomponent(v::PSY.HybridSystem, ::Type{PSY.ThermalGen}) = PSY.get_thermal_unit(v)
get_subcomponent(v::PSY.HybridSystem, ::Type{PSY.RenewableGen}) = PSY.get_renewable_unit(v)
get_subcomponent(v::PSY.HybridSystem, ::Type{PSY.ElectricLoad}) = PSY.get_electric_load(v)
get_subcomponent(v::PSY.HybridSystem, ::Type{PSY.Storage}) = PSY.get_storage(v)

################################ output power constraints ###########################

get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{<:ReactivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = PSY.get_reactive_power_limits(device)

get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{InputActivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = PSY.get_input_active_power_limits(PSY.get_storage(device))

get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{OutputActivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = PSY.get_output_active_power_limits(PSY.get_storage(device))

get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{PSY.RenewableGen},
    ::Type{ComponentActivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = PSY.get_active_power_limits(PSY.get_renewable_unit(device))

get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{ActivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = (
    min=-1 * PSY.get_input_active_power_limits(device).max,
    max=PSY.get_output_active_power_limits(device).max,
)

get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{PSY.ThermalGen},
    ::Type{ComponentActivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = PSY.get_active_power_limits(PSY.get_thermal_unit(device))

get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{PSY.ThermalGen},
    ::Type{ComponentReactivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = PSY.get_reactive_power_limits(PSY.get_thermal_unit(device))

get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{PSY.RenewableGen},
    ::Type{ComponentReactivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = PSY.get_reactive_power_limits(PSY.get_renewable_unit(device))

get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{PSY.Storage},
    ::Type{ComponentReactivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = PSY.get_reactive_power_limits(PSY.get_storage(device))

get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{EnergyCapacityConstraint},
    ::Type{<:AbstractHybridFormulation},
) = PSY.get_state_of_charge_limits(PSY.get_storage(device))

get_min_max_limits(
    device::PSY.HybridSystem,
    ::Type{PSY.ElectricLoad},
    ::Type{ComponentReactivePowerVariableLimitsConstraint},
    ::Type{<:AbstractHybridFormulation},
) = (min=0.0, max=PSY.get_max_reactive_power(device))

########################## Add Variables Calls #############################################
const SUB_COMPONENT_TYPES =
    [PSY.ThermalGen, PSY.RenewableGen, PSY.ElectricLoad, PSY.Storage]
const SUB_COMPONENT_KEYS = ["ThermalGen", "RenewableGen", "ElectricLoad", "Storage"]
const _INPUT_TYPES = [PSY.ElectricLoad, PSY.Storage]
const _OUTPUT_TYPES = [PSY.ThermalGen, PSY.RenewableGen, PSY.Storage]
const _INPUT_KEYS = ["ElectricLoad", "Storage"]
const _OUTPUT_KEYS = ["ThermalGen", "RenewableGen", "Storage"]

function _add_variable!(
    container::OptimizationContainer,
    ::T,
    devices::U,
    formulation::AbstractHybridFormulation,
) where {
    T <: ComponentReactivePowerVariable,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
} where {D <: PSY.HybridSystem}
    @assert !isempty(devices)
    time_steps = get_time_steps(container)
    settings = get_settings(container)
    binary = get_variable_binary(T(), D, formulation)

    variable = add_variable_container!(
        container,
        T(),
        D,
        [PSY.get_name(d) for d in devices],
        SUB_COMPONENT_KEYS,
        time_steps;
        sparse=true,
    )

    for d in devices, (ix, subcomp) in enumerate(SUB_COMPONENT_TYPES)
        !does_subcomponent_exist(d, subcomp) && continue
        subcomp_key = SUB_COMPONENT_KEYS[ix]
        for t in time_steps
            name = PSY.get_name(d)
            variable[name, subcomp_key, t] = JuMP.@variable(
                get_jump_model(container),
                base_name = "$(T)_$(D)_$(subcomp_key)_{$(name), $(t)}",
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
    # Workaround to remove invalid key combinations
    filter!(x -> x.second !== nothing, variable.data)
    return
end

function _add_variable!(
    container::OptimizationContainer,
    ::T,
    devices::U,
    formulation::AbstractHybridFormulation,
) where {
    T <: ComponentInputActivePowerVariable,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
} where {D <: PSY.HybridSystem}
    @assert !isempty(devices)
    time_steps = get_time_steps(container)
    settings = get_settings(container)
    binary = get_variable_binary(T(), D, formulation)

    variable = add_variable_container!(
        container,
        T(),
        D,
        [PSY.get_name(d) for d in devices],
        _INPUT_KEYS,
        time_steps;
        sparse=true,
    )

    for d in devices, (ix, subcomp) in enumerate(_INPUT_TYPES)
        !does_subcomponent_exist(d, subcomp) && continue
        subcomp_key = _INPUT_KEYS[ix]
        for t in time_steps
            name = PSY.get_name(d)
            variable[name, subcomp_key, t] = JuMP.@variable(
                get_jump_model(container),
                base_name = "$(T)_$(D)_$(subcomp)_{$(name), $(t)}",
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
    # Workaround to remove invalid key combinations
    filter!(x -> x.second !== nothing, variable.data)
    return
end

function _add_variable!(
    container::OptimizationContainer,
    ::T,
    devices::U,
    formulation::AbstractHybridFormulation,
) where {
    T <: ComponentOutputActivePowerVariable,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
} where {D <: PSY.HybridSystem}
    @assert !isempty(devices)
    time_steps = get_time_steps(container)
    settings = get_settings(container)
    binary = get_variable_binary(T(), D, formulation)

    variable = add_variable_container!(
        container,
        T(),
        D,
        [PSY.get_name(d) for d in devices],
        _OUTPUT_KEYS,
        time_steps;
        sparse=true,
    )

    for d in devices, (ix, subcomp) in enumerate(_OUTPUT_TYPES)
        !does_subcomponent_exist(d, subcomp) && continue
        subcomp_key = _OUTPUT_KEYS[ix]
        for t in time_steps
            name = PSY.get_name(d)
            variable[name, subcomp_key, t] = JuMP.@variable(
                get_jump_model(container),
                base_name = "$(T)_$(D)_$(subcomp)_{$(name), $(t)}",
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
    # Workaround to remove invalid key combinations
    filter!(x -> x.second !== nothing, variable.data)
    return
end

function _add_variable!(
    container::OptimizationContainer,
    ::T,
    devices::U,
    formulation::AbstractHybridFormulation,
) where {
    T <: Union{ComponentEnergyVariable, ComponentReservationVariable},
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
} where {D <: PSY.HybridSystem}
    @assert !isempty(devices)
    time_steps = get_time_steps(container)
    settings = get_settings(container)
    binary = get_variable_binary(T(), D, formulation)

    variable = add_variable_container!(
        container,
        T(),
        D,
        [PSY.get_name(d) for d in devices if does_subcomponent_exist(d, PSY.Storage)],
        time_steps;
        meta="storage",
    )

    for d in devices
        !does_subcomponent_exist(d, PSY.Storage) && continue
        for t in time_steps
            name = PSY.get_name(d)
            variable[name, t] = JuMP.@variable(
                get_jump_model(container),
                base_name = "$(T)_$(D)_Storage_{$(name), $(t)}",
                binary = binary
            )

            ub = get_variable_upper_bound(T(), d, formulation)
            ub !== nothing && JuMP.set_upper_bound(variable[name, t], ub)

            lb = get_variable_lower_bound(T(), d, formulation)
            lb !== nothing && !binary && JuMP.set_lower_bound(variable[name, t], lb)

            if get_warm_start(settings)
                init = get_variable_warm_start_value(T(), d, formulation)
                init !== nothing && JuMP.set_start_value(variable[name, t], init)
            end
        end
    end
    return
end

"""
Add variables to the OptimizationContainer for a Sub-Component of a hybrid systems.
"""
function add_variables!(
    container::OptimizationContainer,
    ::Type{T},
    devices::Union{Vector{U}, IS.FlattenIteratorWrapper{U}},
    formulation::AbstractHybridFormulation,
) where {
    T <: Union{
        ComponentInputActivePowerVariable,
        ComponentOutputActivePowerVariable,
        ComponentReactivePowerVariable,
    },
    U <: PSY.HybridSystem,
}
    _add_variable!(container, T(), devices, formulation)
    return
end

function add_variables!(
    container::OptimizationContainer,
    ::Type{T},
    devices::Union{Vector{U}, IS.FlattenIteratorWrapper{U}},
    formulation::AbstractHybridFormulation,
) where {
    T <: Union{ComponentEnergyVariable, ComponentReservationVariable},
    U <: PSY.HybridSystem,
}
    if !all(isnothing.(PSY.get_storage.(devices)))
        _add_variable!(container, T(), devices, formulation)
    end
    return
end

################################## Add Expression Calls ####################################
function add_to_expression!(
    container::OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    ::Type{X},
) where {
    T <:
    Union{ComponentActivePowerRangeExpressionUB, ComponentActivePowerRangeExpressionLB},
    U <: Union{ComponentInputActivePowerVariable, ComponentOutputActivePowerVariable},
    V <: PSY.HybridSystem,
    W <: AbstractDeviceFormulation,
    X <: PM.AbstractPowerModel,
}
    time_steps = get_time_steps(container)
    variables = get_variable(container, U(), V)
    expressions = lazy_container_addition!(
        container,
        T(),
        V,
        [PSY.get_name(d) for d in devices],
        SUB_COMPONENT_KEYS,
        time_steps;
        sparse=true,
    )
    for (key, variable) in variables.data
        JuMP.add_to_expression!(expressions.data[key], variable)
    end
    return
end

########################## Add parameters calls ############################################
function add_parameters!(
    container::OptimizationContainer,
    ::Type{T},
    devices::U,
    model::DeviceModel{D, W},
) where {
    T <: TimeSeriesParameter,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractDeviceFormulation,
} where {D <: PSY.HybridSystem}
    if get_rebuild_model(get_settings(container)) && has_container_key(container, T, D)
        return
    end
    _devices = [d for d in devices if PSY.get_renewable_unit(d) !== nothing]
    add_parameters!(container, T(), _devices, model)
    return
end

function add_parameters!(
    container::OptimizationContainer,
    param::T,
    devices::U,
    model::DeviceModel{D, W},
) where {
    T <: ActivePowerTimeSeriesParameter,
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractDeviceFormulation,
} where {D <: PSY.HybridSystem}
    error("HybridSystem is currently unsupported")
    ts_type = get_default_time_series_type(container)
    if !(ts_type <: Union{PSY.AbstractDeterministic, PSY.StaticTimeSeries})
        error("add_parameters! for TimeSeriesParameter is not compatible with $ts_type")
    end
    time_steps = get_time_steps(container)
    base_ts_name = get_time_series_names(model)[T]
    time_series_mult_id = create_time_series_multiplier_index(model, T)
    @debug "adding" T base_ts_name ts_type time_series_mult_id _group =
        LOG_GROUP_OPTIMIZATION_CONTAINER
    sub_comp_type = [PSY.RenewableGen, PSY.ElectricLoad]

    device_names = [PSY.get_name(d) for d in devices]
    initial_values = Dict{String, AbstractArray}()
    for device in devices, comp_type in sub_comp_type
        if does_subcomponent_exist(device, comp_type)
            sub_comp = get_subcomponent(device, comp_type)
            ts_name = PSY.make_subsystem_time_series_name(sub_comp, base_ts_name)
            ts_uuid = get_time_series_uuid(ts_type, device, ts_name)
            initial_values[ts_uuid] =
                get_time_series_initial_values!(container, ts_type, device, ts_name)
            multiplier = get_multiplier_value(T(), device, comp_type, W())
        else
            # TODO: what to do here?
            #ts_vector = zeros(time_steps[end])
            multiplier = 0.0
        end
    end

    parameter_container = add_param_container!(
        container,
        param,
        D,
        ts_type,
        base_ts_name,
        collect(keys(initial_values)),
        device_names,
        string.(sub_comp_type),
        time_steps,
    )
    set_time_series_multiplier_id!(get_attributes(parameter_container), time_series_mult_id)
    jump_model = get_jump_model(container)

    for (ts_uuid, ts_values) in initial_values
        for step in time_steps
            set_parameter!(parameter_container, jump_model, ts_values[step], ts_uuid, step)
        end
    end

    for device in devices, comp_type in sub_comp_type
        name = PSY.get_name(device)
        if does_subcomponent_exist(device, comp_type)
            multiplier = get_multiplier_value(T(), device, comp_type, W())
            sub_comp = get_subcomponent(device, comp_type)
            ts_name = PSY.make_subsystem_time_series_name(sub_comp, base_ts_name)
            ts_uuid = get_time_series_uuid(ts_type, device, ts_name)
            add_component_name!(get_attributes(parameter_container), name, ts_uuid)
        else
            multiplier = 0.0
        end
        for step in time_steps
            set_multiplier!(parameter_container, multiplier, name, string(comp_type), step)
        end
    end
    return
end

########################## Add constraint Calls ############################################
function _add_lower_bound_range_constraints!(
    container::OptimizationContainer,
    T::Type{ComponentActivePowerVariableLimitsConstraint},
    array,
    devices::IS.FlattenIteratorWrapper{V},
    ::DeviceModel{V, W},
) where {V <: PSY.HybridSystem, W <: AbstractDeviceFormulation}
    constraint = T()
    component_type = V
    time_steps = get_time_steps(container)
    device_names =
        [PSY.get_name(d) for d in devices if does_subcomponent_exist(d, PSY.ThermalGen)]

    con_lb = add_constraints_container!(
        container,
        constraint,
        component_type,
        device_names,
        time_steps,
        meta="lb",
    )

    for device in devices, t in time_steps
        !does_subcomponent_exist(device, PSY.ThermalGen) && continue
        ci_name = PSY.get_name(device)
        subcomp_key = string(PSY.ThermalGen)
        limits = get_min_max_limits(device, PSY.ThermalGen, T, W) # depends on constraint type and formulation type
        con_lb[ci_name, t] = JuMP.@constraint(
            get_jump_model(container),
            array[ci_name, subcomp_key, t] >= limits.min
        )
    end
end

function _add_upper_bound_range_constraints!(
    container::OptimizationContainer,
    T::Type{ComponentActivePowerVariableLimitsConstraint},
    array,
    devices::IS.FlattenIteratorWrapper{V},
    ::DeviceModel{V, W},
) where {V <: PSY.HybridSystem, W <: AbstractDeviceFormulation}
    constraint = T()
    component_type = V
    time_steps = get_time_steps(container)
    device_names =
        [PSY.get_name(d) for d in devices if does_subcomponent_exist(d, PSY.ThermalGen)]

    con_ub = add_constraints_container!(
        container,
        constraint,
        component_type,
        device_names,
        time_steps,
        meta="ub",
    )

    for device in devices, t in time_steps
        !does_subcomponent_exist(device, PSY.ThermalGen) && continue
        ci_name = PSY.get_name(device)
        subcomp_key = string(PSY.ThermalGen)
        limits = get_min_max_limits(device, PSY.ThermalGen, T, W) # depends on constraint type and formulation type
        con_ub[ci_name, t] = JuMP.@constraint(
            get_jump_model(container),
            array[ci_name, subcomp_key, t] <= limits.max
        )
    end
end

function _add_parameterized_upper_bound_range_constraints!(
    container::OptimizationContainer,
    T::Type{ComponentActivePowerVariableLimitsConstraint},
    array,
    P::Type{<:ParameterType},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
) where {V <: PSY.HybridSystem, W <: AbstractDeviceFormulation}
    time_steps = get_time_steps(container)
    constraint = T()
    component_type = V
    names =
        [PSY.get_name(d) for d in devices if does_subcomponent_exist(d, PSY.RenewableGen)]

    constraint = add_constraints_container!(
        container,
        constraint,
        component_type,
        names,
        time_steps,
        meta="re ub",
    )

    param_container = get_parameter(container, P(), V)
    parameter_values = get_parameter_values(param_container)
    multiplier = get_parameter_multiplier_array(container, P(), V)
    for device in devices, t in time_steps
        !does_subcomponent_exist(device, PSY.RenewableGen) && continue
        subcomp_key = string(PSY.RenewableGen)
        name = PSY.get_name(device)
        constraint[name, t] = JuMP.@constraint(
            get_jump_model(container),
            array[name, subcomp_key, t] <=
            multiplier[name, subcomp_key, t] * parameter_values[name, subcomp_key, t]
        )
    end
end

function _add_range_constraints!(
    container::OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    ::Type{X},
) where {
    T <: ComponentActivePowerVariableLimitsConstraint,
    U <: VariableType,
    V <: PSY.HybridSystem,
    W <: AbstractDeviceFormulation,
    X <: PM.AbstractPowerModel,
}
    array = get_variable(container, U(), V)
    _add_lower_bound_range_constraints_impl!(container, T, array, devices, model)
    _add_upper_bound_range_constraints_impl!(container, T, array, devices, model)
    _add_parameterized_upper_bound_range_constraints_impl!(
        container,
        T,
        array,
        ActivePowerTimeSeriesParameter(),
        devices,
        model,
    )
    return
end

function PSI.add_constraints!(
    container::OptimizationContainer,
    T::Type{<:PowerVariableLimitsConstraint},
    U::Type{<:Union{VariableType, ExpressionType}},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    X::Type{<:PM.AbstractPowerModel},
) where {V <: PSY.HybridSystem, W <: AbstractHybridFormulation}
    PSI.add_range_constraints!(container, T, U, devices, model, X)
    return
end

function add_constraints!(
    container::OptimizationContainer,
    T::Type{ComponentActivePowerVariableLimitsConstraint},
    U::Type{<:VariableType},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    X::Type{<:PM.AbstractPowerModel},
) where {V <: PSY.HybridSystem, W <: AbstractHybridFormulation}
    array = get_variable(container, U(), V)
    _add_lower_bound_range_constraints!(container, T, array, devices, model)
    _add_upper_bound_range_constraints!(container, T, array, devices, model)
    _add_parameterized_upper_bound_range_constraints!(
        container,
        T,
        array,
        ActivePowerTimeSeriesParameter,
        devices,
        model,
    )
    return
end

function add_constraints!(
    container::OptimizationContainer,
    T::Type{ComponentActivePowerVariableLimitsConstraint},
    U::Type{<:RangeConstraintLBExpressions},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    ::Type{<:PM.AbstractPowerModel},
) where {V <: PSY.HybridSystem, W <: AbstractHybridFormulation}
    array = get_expression(container, U(), V)
    _add_lower_bound_range_constraints!(container, T, array, devices, model)
    return
end

function add_constraints!(
    container::OptimizationContainer,
    T::Type{ComponentActivePowerVariableLimitsConstraint},
    U::Type{<:RangeConstraintUBExpressions},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    ::Type{<:PM.AbstractPowerModel},
) where {V <: PSY.HybridSystem, W <: AbstractHybridFormulation}
    array = get_expression(container, U(), V)
    _add_upper_bound_range_constraints!(container, T, array, devices, model)
    _add_parameterized_upper_bound_range_constraints!(
        container,
        T,
        array,
        ActivePowerTimeSeriesParameter,
        devices,
        model,
    )
    return
end

function add_constraints!(
    container::OptimizationContainer,
    T::Type{InputActivePowerVariableLimitsConstraint},
    U::Type{<:Union{VariableType, ExpressionType}},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    X::Type{<:PM.AbstractPowerModel},
) where {V <: PSY.HybridSystem, W <: AbstractHybridFormulation}
    if get_attribute(model, "reservation")
        add_reserve_range_constraints!(container, T, U, devices, model, X)
    else
        add_range_constraints!(container, T, U, devices, model, X)
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    T::Type{OutputActivePowerVariableLimitsConstraint},
    U::Type{<:Union{VariableType, ExpressionType}},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    X::Type{<:PM.AbstractPowerModel},
) where {V <: PSY.HybridSystem, W <: AbstractHybridFormulation}
    if get_attribute(model, "reservation")
        add_reserve_range_constraints!(container, T, U, devices, model, X)
    else
        add_range_constraints!(container, T, U, devices, model, X)
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    T::Type{ComponentReactivePowerVariableLimitsConstraint},
    ::Type{<:VariableType},
    devices::IS.FlattenIteratorWrapper{V},
    ::DeviceModel{V, W},
    ::Type{<:PM.AbstractPowerModel},
) where {V <: PSY.HybridSystem, W <: AbstractHybridFormulation}
    time_steps = get_time_steps(container)
    var = get_variable(container, ComponentReactivePowerVariable(), V)
    device_names = [PSY.get_name(d) for d in devices]
    subcomp_types = SUB_COMPONENT_TYPES

    constraint_ub = add_constraints_container!(
        container,
        ComponentReactivePowerVariableLimitsConstraint(),
        V,
        device_names,
        subcomp_types,
        time_steps;
        meta="ub",
        sparse=true,
    )
    constraint_lb = add_constraints_container!(
        container,
        ComponentReactivePowerVariableLimitsConstraint(),
        V,
        device_names,
        subcomp_types,
        time_steps;
        meta="lb",
        sparse=true,
    )

    for d in devices, (ix, subcomp) in enumerate(SUB_COMPONENT_TYPES)
        !does_subcomponent_exist(d, subcomp) && continue
        name = PSY.get_name(d)
        limits = get_min_max_limits(d, subcomp, T, W)
        for t in time_steps
            constraint_ub[name, subcomp, t] = JuMP.@constraint(
                get_jump_model(container),
                var[name, SUB_COMPONENT_KEYS[ix], t] <= limits.max
            )
            constraint_lb[name, subcomp, t] = JuMP.@constraint(
                get_jump_model(container),
                var[name, SUB_COMPONENT_KEYS[ix], t] >= limits.min
            )
        end
    end
    return
end
######################## Energy balance constraints ############################
function add_constraints!(
    container::OptimizationContainer,
    ::Type{EnergyBalanceConstraint},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, W},
    ::Type{<:PM.AbstractPowerModel},
) where {V <: PSY.HybridSystem, W <: AbstractHybridFormulation}
    time_steps = get_time_steps(container)
    resolution = get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / MINUTES_IN_HOUR
    initial_conditions = get_initial_condition(container, ComponentInitialEnergyLevel(), V)
    energy_var = get_variable(container, ComponentEnergyVariable(), V, "storage")
    names = axes(energy_var)[1]
    powerin_var = get_variable(container, ComponentInputActivePowerVariable(), V)
    powerout_var = get_variable(container, ComponentOutputActivePowerVariable(), V)

    constraint = add_constraints_container!(
        container,
        EnergyBalanceConstraint(),
        V,
        names,
        time_steps,
    )

    for ic in initial_conditions
        device = get_component(ic)
        does_subcomponent_exist(device, PSY.Storage) && continue
        storage_device = PSY.get_storage(device)
        efficiency = PSY.get_efficiency(storage_device)
        name = PSY.get_name(device)
        constraint[name, 1] = JuMP.@constraint(
            get_jump_model(container),
            energy_var[name, 1] ==
            get_value(ic) +
            (
                powerin_var[name, "Storage", 1] * efficiency.in -
                (powerout_var[name, "Storage", 1] / efficiency.out)
            ) * fraction_of_hour
        )

        for t in time_steps[2:end]
            constraint[name, t] = JuMP.@constraint(
                get_jump_model(container),
                energy_var[name, t] ==
                energy_var[name, t - 1] +
                (
                    powerin_var[name, "Storage", t] * efficiency.in -
                    (powerout_var[name, "Storage", t] / efficiency.out)
                ) * fraction_of_hour
            )
        end
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{DeviceNetActivePowerConstraint},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, D},
    ::Type{X},
) where {V <: PSY.HybridSystem, D <: AbstractHybridFormulation, X <: PM.AbstractPowerModel}
    time_steps = get_time_steps(container)
    name_index = [PSY.get_name(d) for d in devices]

    var_sub_in = get_variable(container, ComponentInputActivePowerVariable(), V)
    var_sub_out = get_variable(container, ComponentOutputActivePowerVariable(), V)
    var_out = get_variable(container, PSI.ActivePowerOutVariable(), V)
    var_in = get_variable(container, PSI.ActivePowerInVariable(), V)

    constraint_in = add_constraints_container!(
        container,
        DeviceNetActivePowerConstraint(),
        V,
        name_index,
        time_steps,
        meta="in",
    )
    constraint_out = add_constraints_container!(
        container,
        DeviceNetActivePowerConstraint(),
        V,
        name_index,
        time_steps,
        meta="out",
    )

    for d in devices
        name = PSY.get_name(d)
        for t in time_steps
            total_power_in = JuMP.AffExpr()
            total_power_out = JuMP.AffExpr()
            for subcomp in _OUTPUT_TYPES
                !does_subcomponent_exist(d, subcomp) && continue
                JuMP.add_to_expression!(
                    total_power_out,
                    var_sub_out[name, string(subcomp), t],
                )
            end
            for subcomp in _INPUT_TYPES
                !does_subcomponent_exist(d, subcomp) && continue
                JuMP.add_to_expression!(
                    total_power_in,
                    var_sub_in[name, string(subcomp), t],
                )
            end
            constraint_out[name, t] = JuMP.@constraint(
                get_jump_model(container),
                var_out[name, t] - total_power_out == 0.0
            )
            constraint_in[name, t] = JuMP.@constraint(
                get_jump_model(container),
                var_in[name, t] - total_power_in == 0.0
            )
        end
    end

    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{DeviceNetReactivePowerConstraint},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, D},
    ::Type{X},
) where {V <: PSY.HybridSystem, D <: AbstractHybridFormulation, X <: PM.AbstractPowerModel}
    time_steps = get_time_steps(container)
    name_index = [PSY.get_name(d) for d in devices]

    var_q = get_variable(container, ReactivePowerVariable(), V)
    var_sub_q = get_variable(container, ComponentReactivePowerVariable(), V)

    constraint = add_constraints_container!(
        container,
        DeviceNetReactivePowerConstraint(),
        V,
        name_index,
        time_steps,
    )

    for d in devices
        name = PSY.get_name(d)
        for t in time_steps
            net_reactive_power = JuMP.AffExpr()
            for subcomp in SUB_COMPONENT_TYPES
                !does_subcomponent_exist(d, subcomp) && continue
                if subcomp <: PSY.ElectricLoad
                    JuMP.add_to_expression!(
                        net_reactive_power,
                        var_sub_q[name, string(subcomp), t],
                        -1.0,
                    )
                else
                    JuMP.add_to_expression!(
                        net_reactive_power,
                        var_sub_q[name, string(subcomp), t],
                    )
                end
            end
            constraint[name, t] = JuMP.@constraint(
                get_jump_model(container),
                var_q[name, t] - net_reactive_power == 0.0
            )
        end
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{InterConnectionLimitConstraint},
    devices::IS.FlattenIteratorWrapper{V},
    model::DeviceModel{V, D},
    ::Type{X},
) where {V <: PSY.HybridSystem, D <: AbstractHybridFormulation, X <: PM.AbstractPowerModel}
    time_steps = get_time_steps(container)
    name_index = [PSY.get_name(d) for d in devices]

    var_q = get_variable(container, ReactivePowerVariable(), V)
    var_p_in = get_variable(container, PSI.ActivePowerOutVariable(), V)
    var_p_out = get_variable(container, PSI.ActivePowerInVariable(), V)

    constraint = add_constraints_container!(
        container,
        InterConnectionLimitConstraint(),
        V,
        name_index,
        time_steps,
    )

    for d in devices, t in time_steps
        name = PSY.get_name(d)
        rating = PSY.get_interconnection_rating(d)
        constraint[name, t] = JuMP.@constraint(
            get_jump_model(container),
            rating^2 == var_q[name, t]^2 + var_p_in[name, t]^2 + var_p_out[name, t]^2
        )
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{ComponentReservationConstraint},
    devices::IS.FlattenIteratorWrapper{T},
    model::DeviceModel{T, D},
    ::Type{<:PM.AbstractPowerModel},
) where {T <: PSY.HybridSystem, D <: AbstractHybridFormulation}
    time_steps = get_time_steps(container)
    var_in = get_variable(container, ComponentInputActivePowerVariable(), T)
    var_out = get_variable(container, ComponentOutputActivePowerVariable(), T)
    reserve = get_variable(container, ReservationVariable(), T)
    names = [PSY.get_name(x) for x in devices if does_subcomponent_exist(x, PSY.Storage)]
    con_in = add_constraints_container!(
        container,
        ComponentReservationConstraint(),
        T,
        names,
        time_steps;
        meta="in",
    )
    con_out = add_constraints_container!(
        container,
        ReserveEnergyCoverageConstraint(),
        T,
        names,
        time_steps;
        meta="out",
    )

    for d in devices
        !does_subcomponent_exist(d, PSY.Storage) && continue
        name = PSY.get_name(d)
        out_limits = PSY.get_output_active_power_limits(d)
        in_limits = PSY.get_input_active_power_limits(d)
        for t in time_steps
            con_in[name, t] = JuMP.@constraint(
                get_jump_model(container),
                var_in[name, "Storage", t] <= in_limits.max * (1 - reserve[name, t])
            )
            con_out[name, t] = JuMP.@constraint(
                get_jump_model(container),
                var_out[name, "Storage", t] <= out_limits.max * reserve[name, t]
            )
        end
    end
    return
end

#=
function add_constraints!(
    container::OptimizationContainer,
    ::Type{ReserveEnergyCoverageConstraint},
    devices::IS.FlattenIteratorWrapper{T},
    model::DeviceModel{T, D},
    ::Type{<:PM.AbstractPowerModel},
) where {T <: PSY.HybridSystem, D <: AbstractHybridFormulation}
    time_steps = get_time_steps(container)
    var_e = get_variable(container, EnergyVariable(), T)
    r_up = get_variable(container, ComponentActivePowerReserveUpVariable(), T)
    r_dn = get_variable(container, ComponentActivePowerReserveDownVariable(), T)
    names = [PSY.get_name(x) for x in devices if does_subcomponent_exist(d, PSY.Storage)]
    con_up = add_constraints_container!(
        container,
        ReserveEnergyCoverageConstraint(),
        T,
        names,
        time_steps,
        meta="up",
    )
    con_dn = add_constraints_container!(
        container,
        ReserveEnergyCoverageConstraint(),
        T,
        names,
        time_steps,
        meta="dn",
    )

    for d in devices, t in time_steps
        !does_subcomponent_exist(d, PSY.Storage) && continue
        name = PSY.get_name(d)
        limits = PSY.get_state_of_charge_limits(PSY.get_storage(d))
        efficiency = PSY.get_efficiency(d)
        con_up[name, t] = JuMP.@constraint(
            get_jump_model(container),
            r_up[name, t] <= (var_e[name, t] - limits.min) * efficiency.out
        )
        con_dn[name, t] = JuMP.@constraint(
            get_jump_model(container),
            r_dn[name, t] <= (limits.max - var_e[name, t]) / efficiency.in
        )
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{RangeLimitConstraint},
    devices::IS.FlattenIteratorWrapper{T},
    model::DeviceModel{T, D},
    ::Type{<:PM.AbstractPowerModel},
) where {T <: PSY.HybridSystem, D <: AbstractHybridFormulation}
    time_steps = get_time_steps(container)
    var_in = get_variable(container, PSI.ActivePowerOutVariable(), T)
    var_out = get_variable(container, PSI.ActivePowerOutVariable(), T)
    r_up = get_variable(container, ComponentActivePowerReserveUpVariable(), T)
    r_dn = get_variable(container, ComponentActivePowerReserveDownVariable(), T)
    names = [PSY.get_name(x) for x in devices]
    con_up = add_constraints_container!(
        container,
        RangeLimitConstraint(),
        T,
        names,
        time_steps,
        meta="up",
    )
    con_dn = add_constraints_container!(
        container,
        RangeLimitConstraint(),
        T,
        names,
        time_steps,
        meta="dn",
    )

    for d in devices, t in time_steps
        name = PSY.get_name(d)
        out_limits = PSY.get_output_active_power_limits(d)
        in_limits = PSY.get_input_active_power_limits(d)
        con_up[name, t] = JuMP.@constraint(
            get_jump_model(container),
            r_up[name, t] <= var_in[name, t] + (out_limits.max - var_out[name, t])
        )
        con_dn[name, t] = JuMP.@constraint(
            get_jump_model(container),
            r_dn[name, t] <= var_out[name, t] + (in_limits.max - var_in[name, t])
        )
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{ComponentReserveUpBalance},
    devices::IS.FlattenIteratorWrapper{T},
    model::DeviceModel{T, D},
    ::Type{<:PM.AbstractPowerModel},
) where {T <: PSY.HybridSystem, D <: AbstractHybridFormulation}
    time_steps = get_time_steps(container)
    sub_r_up = get_variable(container, ComponentActivePowerReserveUpVariable(), T)
    sub_expr_up = get_expression(container, ComponentReserveUpBalanceExpression(), T)
    names = [PSY.get_name(x) for x in devices]
    con_up = add_constraints_container!(
        container,
        ComponentReserveUpBalance(),
        T,
        names,
        time_steps,
    )

    for d in devices, t in time_steps
        name = PSY.get_name(d)
        con_up[name, t] = JuMP.@constraint(
            get_jump_model(container),
            sub_expr_up[name, t] == sum(
                sub_r_up[name, string(sub_comp_type), t] for
                sub_comp_type in [PSY.ThermalGen, PSY.RenewableGen, PSY.Storage]
            )
        )
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{ComponentReserveDownBalance},
    devices::IS.FlattenIteratorWrapper{T},
    model::DeviceModel{T, D},
    ::Type{<:PM.AbstractPowerModel},
) where {T <: PSY.HybridSystem, D <: AbstractHybridFormulation}
    time_steps = get_time_steps(container)
    sub_r_dn = get_variable(container, ComponentActivePowerReserveDownVariable(), T)
    sub_expr_dn = get_expression(container, ComponentReserveDownBalanceExpression(), T)
    names = [PSY.get_name(x) for x in devices]
    con_dn = add_constraints_container!(
        container,
        ComponentReserveDownBalance(),
        T,
        names,
        time_steps,
    )

    for d in devices, t in time_steps
        name = PSY.get_name(d)
        con_dn[name, t] = JuMP.@constraint(
            get_jump_model(container),
            sub_expr_dn[name, t] == sum(
                sub_r_dn[name, string(sub_comp_type), t] for
                sub_comp_type in [PSY.ThermalGen, PSY.RenewableGen, PSY.Storage]
            )
        )
    end
    return
end
=#
########################## Make initial Conditions for a Model #############################
function initial_conditions!(
    container::OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{D},
    formulation::AbstractHybridFormulation,
) where {D <: PSY.HybridSystem}
    add_initial_condition!(container, devices, formulation, ComponentInitialEnergyLevel())
    return
end

########################### Cost Function Calls#############################################
function objective_function!(
    container::OptimizationContainer,
    devices::IS.FlattenIteratorWrapper{T},
    ::DeviceModel{T, U},
    ::Type{<:PM.AbstractPowerModel},
) where {T <: PSY.HybridSystem, U <: AbstractHybridFormulation}
    add_variable_cost!(container, PSI.ActivePowerOutVariable(), devices, U())
    add_variable_cost!(container, PSI.ActivePowerInVariable(), devices, U())
    add_proportional_cost!(container, OnVariable(), devices, U())
    return
end

## BUILD IMPL

#=
function PSI.build_impl!(decision_model::PSI.DecisionModel{MerchantHybridEnergyOnly})
    container = PSI.get_optimization_container(decision_model)
    #settings = PSI.get_settings(container)
    model = PSI.get_jump_model(container)
    s = PSI.get_system(decision_model)
    PSI.init_optimization_container!(container, PSI.CopperPlatePowerModel, s)
    PSI.init_model_store_params!(decision_model)
    ext = PSY.get_ext(s)
    ###############################
    ######## Create Sets ##########
    ###############################

    dates_da = ext["λ_da_df"][!, "DateTime"]
    dates_rt = ext["λ_rt_df"][!, "DateTime"]
    len_DA = get(ext, "horizon_DA", length(dates_da))
    len_RT = get(ext, "horizon_RT", length(dates_rt))
    T_da = 1:len_DA
    T_rt = 1:len_RT
    container.time_steps = T_rt

    tmap = [div(k - 1, Int(length(T_rt) / length(T_da))) + 1 for k in T_rt]

    ###############################
    ######## Parameters ###########
    ###############################

    # This Information should be extracted from the system
    # However, we need DA and RT data, and the problem
    # probably have only information about one system

    Bus_name = "Chuhsi"

    # Hard Code for now
    P_max_pcc = 10.0 # Infinity
    VOM = 500.0
    Δt_DA = 1.0
    Δt_RT = 5 / 60
    Cycles = 4.11

    # Thermal Params
    P_max_th = _get_row_val(ext["th_df"], "P_max")
    P_min_th = _get_row_val(ext["th_df"], "P_min")
    C_th_var = _get_row_val(ext["th_df"], "C_var") * 100.0 # Multiply by 100 to transform to $/pu
    C_th_fix = _get_row_val(ext["th_df"], "C_fix")

    # Battery Params
    P_ch_max = _get_row_val(ext["b_df"], "P_ch_max")
    P_ds_max = _get_row_val(ext["b_df"], "P_ds_max")
    η_ch = _get_row_val(ext["b_df"], "η_in")
    η_ds = _get_row_val(ext["b_df"], "η_out")
    inv_η_ds = 1.0 / η_ds
    E_max = _get_row_val(ext["b_df"], "SoC_max")
    E_min = _get_row_val(ext["b_df"], "SoC_min")
    E0 = _get_row_val(ext["b_df"], "initial_energy")

    # Renewable Forecast
    P_re_star = ext["P_rt"][!, "MaxPower"]

    # Load Forecast
    P_ld = ext["Pload_rt"][!, "MaxPower"] * 0.0

    # Forecast Prices
    λ_da = ext["λ_da_df"][!, Bus_name] * 100.0 # Multiply by 100 to transform to $/pu
    λ_rt = ext["λ_rt_df"][!, Bus_name] * 100.0 # Multiply by 100 to transform to $/pu

    # Add Market variables
    add_variable!(decision_model, EnergyDABidOut(), T_da, 0.0, P_max_pcc)
    add_variable!(decision_model, EnergyDABidIn(), T_da, 0.0, P_max_pcc)
    add_variable!(decision_model, EnergyRTBidOut(), T_rt, 0.0, P_max_pcc)
    add_variable!(decision_model, EnergyRTBidIn(), T_rt, 0.0, P_max_pcc)

    # Add PCC Variables
    add_variable!(decision_model, PSI.ActivePowerOutVariable(), T_rt, 0.0, P_max_pcc)
    add_variable!(decision_model, PSI.ActivePowerInVariable(), T_rt, 0.0, P_max_pcc)
    add_binary_variable!(decision_model, PSI.ReservationVariable(), T_rt)

    # Add Thermal Vars: No Thermal For now
    add_variable!(decision_model, ThermalPower(), T_rt, 0.0, P_max_th)
    add_binary_variable!(decision_model, OnVariable(), T_da)

    # Add Renewable Variables
    add_variable!(decision_model, RenewablePower(), T_rt, 0.0, P_re_star)

    # Add Battery Variables
    add_variable!(decision_model, BatteryCharge(), T_rt, 0.0, P_ch_max)
    add_variable!(decision_model, BatteryDischarge(), T_rt, 0.0, P_ds_max)
    add_variable!(decision_model, PSI.EnergyVariable(), T_rt, E_min, E_max)
    add_binary_variable!(decision_model, BatteryStatus(), T_rt)

    ###############################
    ####### Obj. Function #########
    ###############################

    # DA costs
    eb_da_out = PSI.get_variable(container, EnergyDABidOut(), PSY.HybridSystem)
    eb_da_in = PSI.get_variable(container, EnergyDABidIn(), PSY.HybridSystem)
    on_th = PSI.get_variable(container, OnVariable(), PSY.HybridSystem)

    for t in T_da
        lin_cost_da_out = Δt_DA * λ_da[t] * eb_da_out[t]
        lin_cost_da_in = -Δt_DA * λ_da[t] * eb_da_in[t]
        lin_cost_on_th = -Δt_DA * C_th_fix * on_th[t]
        PSI.add_to_objective_invariant_expression!(container, lin_cost_da_out)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_da_in)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_on_th)
    end

    # RT costs
    eb_rt_out = PSI.get_variable(container, EnergyRTBidOut(), PSY.HybridSystem)
    eb_rt_in = PSI.get_variable(container, EnergyRTBidIn(), PSY.HybridSystem)
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), PSY.HybridSystem)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), PSY.HybridSystem)
    status = PSI.get_variable(container, ReservationVariable(), PSY.HybridSystem)
    p_th = PSI.get_variable(container, ThermalPower(), PSY.HybridSystem)
    p_re = PSI.get_variable(container, RenewablePower(), PSY.HybridSystem)
    p_ch = PSI.get_variable(container, BatteryCharge(), PSY.HybridSystem)
    p_ds = PSI.get_variable(container, BatteryDischarge(), PSY.HybridSystem)
    e_st = PSI.get_variable(container, PSI.EnergyVariable(), PSY.HybridSystem)
    status_st = PSI.get_variable(container, BatteryStatus(), PSY.HybridSystem)

    for t in T_rt
        lin_cost_rt_out = Δt_RT * λ_rt[t] * eb_rt_out[t]
        lin_cost_rt_in = -Δt_RT * λ_rt[t] * eb_rt_in[t]
        lin_cost_dart_out = -Δt_RT * λ_rt[t] * eb_da_out[tmap[t]]
        lin_cost_dart_in = Δt_RT * λ_rt[t] * eb_da_in[tmap[t]]
        lin_cost_p_th = -Δt_RT * C_th_var * p_th[t]
        lin_cost_p_ch = -Δt_RT * VOM * p_ch[t]
        lin_cost_p_ds = -Δt_RT * VOM * p_ds[t]
        PSI.add_to_objective_invariant_expression!(container, lin_cost_rt_out)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_rt_in)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_dart_out)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_dart_in)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_p_th)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_p_ch)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_p_ds)
    end
    JuMP.@objective(model, MOI.MAX_SENSE, container.objective_function.invariant_terms)

    ###############################
    ######## Constraints ##########
    ###############################

    # BidBalance
    constraint_eb_out =
        PSI.add_constraints_container!(container, BidBalanceOut(), PSY.HybridSystem, T_rt)
    constraint_eb_in =
        PSI.add_constraints_container!(container, BidBalanceIn(), PSY.HybridSystem, T_rt)

    constraint_status_bid_in =
        PSI.add_constraints_container!(container, StatusInOn(), PSY.HybridSystem, T_rt)

    constraint_status_bid_out =
        PSI.add_constraints_container!(container, StatusOutOn(), PSY.HybridSystem, T_rt)

    constraint_balance = PSI.add_constraints_container!(
        container,
        EnergyAssetBalance(),
        PSY.HybridSystem,
        T_rt,
    )

    # Thermal
    constraint_thermal_on = PSI.add_constraints_container!(
        container,
        ThermalOnVariableUb(),
        PSY.HybridSystem,
        T_rt,
    )

    constraint_thermal_off = PSI.add_constraints_container!(
        container,
        ThermalOnVariableLb(),
        PSY.HybridSystem,
        T_rt,
    )
    # Battery Charging
    constraint_battery_charging = PSI.add_constraints_container!(
        container,
        BatteryStatusChargeOn(),
        PSY.HybridSystem,
        T_rt,
    )

    constraint_battery_discharging = PSI.add_constraints_container!(
        container,
        BatteryStatusDischargeOn(),
        PSY.HybridSystem,
        T_rt,
    )

    constraint_battery_balance =
        PSI.add_constraints_container!(container, BatteryBalance(), PSY.HybridSystem, T_rt)

    constraint_cycling_charge =
        PSI.add_constraints_container!(container, CyclingCharge(), PSY.HybridSystem, 1)

    constraint_cycling_discharge =
        PSI.add_constraints_container!(container, CyclingDischarge(), PSY.HybridSystem, 1)

    for t in T_rt
        # Market Constraint Bids in/out
        constraint_eb_out[t] = JuMP.@constraint(model, eb_rt_out[t] == p_out[t])
        constraint_eb_in[t] = JuMP.@constraint(model, eb_rt_in[t] == p_in[t])
        # Status Bids
        constraint_status_bid_in[t] =
            JuMP.@constraint(model, (1.0 - status[t]) * P_max_pcc .>= p_in[t])
        constraint_status_bid_out[t] =
            JuMP.@constraint(model, status[t] * P_max_pcc .>= p_out[t])
        # Power Balance
        constraint_balance[t] = JuMP.@constraint(
            model,
            p_th[t] + p_re[t] + p_ds[t] - p_ch[t] - P_ld[t] - p_out[t] + p_in[t] == 0.0
        )
        # Thermal Status
        constraint_thermal_on[t] =
            JuMP.@constraint(model, p_th[t] <= on_th[tmap[t]] * P_max_th)
        constraint_thermal_off[t] =
            JuMP.@constraint(model, p_th[t] >= on_th[tmap[t]] * P_min_th)
        # Battery Constraints
        constraint_battery_charging[t] =
            JuMP.@constraint(model, p_ch[t] <= (1.0 - status_st[t]) * P_ch_max)
        constraint_battery_discharging[t] =
            JuMP.@constraint(model, p_ds[t] <= status_st[t] * P_ds_max)
        # Battery Energy Constraints
        if t == 1
            constraint_battery_balance[t] = JuMP.@constraint(
                model,
                E0 + Δt_RT * (p_ch[t] * η_ch - p_ds[t] * inv_η_ds) == e_st[t]
            )
        else
            constraint_battery_balance[t] = JuMP.@constraint(
                model,
                e_st[t - 1] + Δt_RT * (p_ch[t] * η_ch - p_ds[t] * inv_η_ds) == e_st[t]
            )
        end
    end
    # Cycling Constraints
    constraint_cycling_charge[1] =
        JuMP.@constraint(model, inv_η_ds * Δt_RT * sum(p_ds) <= Cycles * E_max)
    constraint_cycling_discharge[1] =
        JuMP.@constraint(model, η_ch * Δt_RT * sum(p_ch) <= Cycles * E_max)

    # Fix Thermal Variable
    JuMP.fix.(on_th, 0, force=true)
    return
end

function PSI.build_impl!(decision_model::PSI.DecisionModel{MerchantHybridCooptimized})
    container = PSI.get_optimization_container(decision_model)
    #settings = PSI.get_settings(container)
    model = PSI.get_jump_model(container)
    s = PSI.get_system(decision_model)
    PSI.init_optimization_container!(container, PSI.CopperPlatePowerModel, s)
    PSI.init_model_store_params!(decision_model)
    ext = PSY.get_ext(s)
    ###############################
    ######## Create Sets ##########
    ###############################

    dates_da = ext["λ_da_df"][!, "DateTime"]
    dates_rt = ext["λ_rt_df"][!, "DateTime"]
    len_DA = get(ext, "horizon_DA", length(dates_da))
    len_RT = get(ext, "horizon_RT", length(dates_rt))
    T_da = 1:len_DA
    T_rt = 1:len_RT
    container.time_steps = T_rt

    tmap = [div(k - 1, Int(length(T_rt) / length(T_da))) + 1 for k in T_rt]

    ###############################
    ######## Parameters ###########
    ###############################

    # This Information should be extracted from the system
    # However, we need DA and RT data, and the problem
    # probably have only information about one system

    Bus_name = "Chuhsi"

    # Hard Code for now
    P_max_pcc = 10.0 # Infinity
    VOM = 500.0
    Δt_DA = 1.0
    Δt_RT = 5 / 60
    Cycles = 4.11
    R_up = 0.333 # Ancillary Services Expected Deployment
    R_dn = 0.333
    R_spin = 0.333
    N = 12 # Number of periods of compliance: 12 * 5 minutes = 1 hour

    # Thermal Params
    P_max_th = _get_row_val(ext["th_df"], "P_max")
    P_min_th = _get_row_val(ext["th_df"], "P_min")
    C_th_var = _get_row_val(ext["th_df"], "C_var") * 100.0 # Multiply by 100 to transform to $/pu
    C_th_fix = _get_row_val(ext["th_df"], "C_fix")

    # Battery Params
    P_ch_max = _get_row_val(ext["b_df"], "P_ch_max")
    P_ds_max = _get_row_val(ext["b_df"], "P_ds_max")
    η_ch = _get_row_val(ext["b_df"], "η_in")
    η_ds = _get_row_val(ext["b_df"], "η_out")
    inv_η_ds = 1.0 / η_ds
    E_max = _get_row_val(ext["b_df"], "SoC_max")
    E_min = _get_row_val(ext["b_df"], "SoC_min")
    E0 = _get_row_val(ext["b_df"], "initial_energy")

    # Renewable Forecast
    P_re_star = ext["P_rt"][!, "MaxPower"]

    # Load Forecast
    P_ld = ext["Pload_rt"][!, "MaxPower"] #* 0.0

    # Forecast Prices
    λ_da = ext["λ_da_df"][!, Bus_name] * 100.0 # Multiply by 100 to transform to $/pu
    λ_rt = ext["λ_rt_df"][!, Bus_name] * 100.0 # Multiply by 100 to transform to $/pu
    λ_da_regup = ext["λ_da_df"][!, "Reg_Up_Prices"] * 100.0 # Multiply by 100 to transform to $/pu
    λ_da_regdown = ext["λ_da_df"][!, "Reg_Down_Prices"] * 100.0 # Multiply by 100 to transform to $/pu
    λ_da_spin = ext["λ_da_df"][!, "Reg_Spin_Prices"] * 100.0 # Multiply by 100 to transform to $/pu

    # Add Market variables
    add_variable!(decision_model, EnergyDABidOut(), T_da, 0.0, P_max_pcc) #eb_da_out
    add_variable!(decision_model, EnergyDABidIn(), T_da, 0.0, P_max_pcc) #eb_da_in
    add_variable!(decision_model, EnergyRTBidOut(), T_rt, 0.0, P_max_pcc) #eb_rt_out
    add_variable!(decision_model, EnergyRTBidIn(), T_rt, 0.0, P_max_pcc) #eb_rt_in

    # Internal Energy Asset Bid variables
    add_variable!(decision_model, EnergyThermalBid(), T_rt, 0.0, P_max_th) #eb_rt_th
    add_variable!(decision_model, EnergyRenewableBid(), T_rt, 0.0, e5) #eb_rt_re
    add_variable!(decision_model, EnergyBatteryChargeBid(), T_rt, 0.0, P_ch_max) #eb_rt_ch
    add_variable!(decision_model, EnergyBatteryDischargeBid(), T_rt, 0.0, P_ds_max) #eb_rt_ds

    # AS Total DA Bids
    add_variable!(decision_model, RegUpDABidOut(), T_da, 0.0, P_max_pcc) #sb_ru_da_out
    add_variable!(decision_model, RegUpDABidIn(), T_da, 0.0, P_max_pcc) #sb_ru_da_in
    add_variable!(decision_model, SpinDABidOut(), T_da, 0.0, P_max_pcc) #sb_spin_da_out
    add_variable!(decision_model, SpinDABidIn(), T_da, 0.0, P_max_pcc) #sb_spin_da_in
    add_variable!(decision_model, RegDownDABidOut(), T_da, 0.0, P_max_pcc) #sb_rd_da_out
    add_variable!(decision_model, RegDownDABidIn(), T_da, 0.0, P_max_pcc) #sb_rd_da_in

    # AS Total RT Bids
    add_variable!(decision_model, RegUpRTBidOut(), T_rt, 0.0, P_max_pcc) #sb_ru_rt_out
    add_variable!(decision_model, RegUpRTBidIn(), T_rt, 0.0, P_max_pcc) #sb_ru_rt_in
    add_variable!(decision_model, SpinRTBidOut(), T_rt, 0.0, P_max_pcc) #sb_spin_rt_out
    add_variable!(decision_model, SpinRTBidIn(), T_rt, 0.0, P_max_pcc) #sb_spin_rt_in
    add_variable!(decision_model, RegDownRTBidOut(), T_rt, 0.0, P_max_pcc) #sb_rd_rt_out
    add_variable!(decision_model, RegDownRTBidIn(), T_rt, 0.0, P_max_pcc) #sb_rd_rt_in

    # AS Thermal RT Internal Bids
    add_variable!(decision_model, RegUpThermalBid(), T_rt, 0.0, P_max_th) #sb_ru_th
    add_variable!(decision_model, SpinThermalBid(), T_rt, 0.0, P_max_th) #sb_spin_th
    add_variable!(decision_model, RegDownThermalBid(), T_rt, 0.0, P_max_th) #sb_rd_th

    # AS Renewable RT Internal Bids
    add_variable!(decision_model, RegUpRenewableBid(), T_rt, 0.0, P_re_star) #sb_ru_re
    add_variable!(decision_model, SpinRenewableBid(), T_rt, 0.0, P_re_star) #sb_spin_re
    add_variable!(decision_model, RegDownRenewableBid(), T_rt, 0.0, P_re_star) #sb_rd_re

    # AS Battery Charge RT Internal Bids
    add_variable!(decision_model, RegUpBatteryChargeBid(), T_rt, 0.0, P_ch_max) #sb_ru_ch
    add_variable!(decision_model, SpinBatteryChargeBid(), T_rt, 0.0, P_ch_max) #sb_spin_ch
    add_variable!(decision_model, RegDownBatteryChargeBid(), T_rt, 0.0, P_ch_max) #sb_rd_ch

    # AS Battery Charge RT Internal Bids
    add_variable!(decision_model, RegUpBatteryDischargeBid(), T_rt, 0.0, P_ds_max) #sb_ru_ds
    add_variable!(decision_model, SpinBatteryDischargeBid(), T_rt, 0.0, P_ds_max) #sb_spin_ds
    add_variable!(decision_model, RegDownBatteryDischargeBid(), T_rt, 0.0, P_ds_max) #sb_rd_ds

    # Add PCC Variables
    add_variable!(decision_model, PSI.ActivePowerOutVariable(), T_rt, 0.0, P_max_pcc)
    add_variable!(decision_model, PSI.ActivePowerInVariable(), T_rt, 0.0, P_max_pcc)
    add_binary_variable!(decision_model, ReservationVariable(), T_rt)

    # Add Thermal Power Vars
    add_variable!(decision_model, ThermalPower(), T_rt, 0.0, P_max_th)
    add_binary_variable!(decision_model, OnVariable(), T_da)

    # Add Renewable Variables
    add_variable!(decision_model, RenewablePower(), T_rt, 0.0, P_re_star)

    # Add Battery Variables
    add_variable!(decision_model, BatteryCharge(), T_rt, 0.0, P_ch_max)
    add_variable!(decision_model, BatteryDischarge(), T_rt, 0.0, P_ds_max)
    add_variable!(decision_model, PSI.EnergyVariable(), T_rt, E_min, E_max)
    add_binary_variable!(decision_model, BatteryStatus(), T_rt)

    ###############################
    ####### Obj. Function #########
    ###############################

    # DA costs
    eb_da_out = PSI.get_variable(container, EnergyDABidOut(), PSY.HybridSystem)
    eb_da_in = PSI.get_variable(container, EnergyDABidIn(), PSY.HybridSystem)
    on_th = PSI.get_variable(container, OnVariable(), PSY.HybridSystem)
    sb_ru_da_out = PSI.get_variable(container, RegUpDABidOut(), PSY.HybridSystem)
    sb_ru_da_in = PSI.get_variable(container, RegUpDABidIn(), PSY.HybridSystem)
    sb_spin_da_out = PSI.get_variable(container, SpinDABidOut(), PSY.HybridSystem)
    sb_spin_da_in = PSI.get_variable(container, SpinDABidIn(), PSY.HybridSystem)
    sb_rd_da_out = PSI.get_variable(container, RegDownDABidOut(), PSY.HybridSystem)
    sb_rd_da_in = PSI.get_variable(container, RegDownDABidIn(), PSY.HybridSystem)

    for t in T_da
        lin_cost_da_out = Δt_DA * λ_da[t] * eb_da_out[t]
        lin_cost_da_in = -Δt_DA * λ_da[t] * eb_da_in[t]
        lin_cost_on_th = -Δt_DA * C_th_fix * on_th[t]
        lin_cost_reg_up = Δt_DA * λ_da_regup[t] * (sb_ru_da_out[t] + sb_ru_da_in[t])
        lin_cost_spin = Δt_DA * λ_da_spin[t] * (sb_spin_da_out[t] + sb_spin_da_in[t])
        lin_cost_reg_down = Δt_DA * λ_da_regdown[t] * (sb_rd_da_out[t] + sb_rd_da_in[t])
        PSI.add_to_objective_invariant_expression!(container, lin_cost_da_out)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_da_in)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_on_th)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_reg_up)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_spin)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_reg_down)
    end

    # RT costs
    eb_rt_out = PSI.get_variable(container, EnergyRTBidOut(), PSY.HybridSystem)
    eb_rt_in = PSI.get_variable(container, EnergyRTBidIn(), PSY.HybridSystem)
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), PSY.HybridSystem)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), PSY.HybridSystem)
    status = PSI.get_variable(container, ReservationVariable(), PSY.HybridSystem)
    p_th = PSI.get_variable(container, ThermalPower(), PSY.HybridSystem)
    p_re = PSI.get_variable(container, RenewablePower(), PSY.HybridSystem)
    p_ch = PSI.get_variable(container, BatteryCharge(), PSY.HybridSystem)
    p_ds = PSI.get_variable(container, BatteryDischarge(), PSY.HybridSystem)
    e_st = PSI.get_variable(container, PSI.EnergyVariable(), PSY.HybridSystem)
    status_st = PSI.get_variable(container, BatteryStatus(), PSY.HybridSystem)

    for t in T_rt
        lin_cost_rt_out = Δt_RT * λ_rt[t] * p_out[t]
        lin_cost_rt_in = -Δt_RT * λ_rt[t] * p_in[t]
        lin_cost_dart_out = -Δt_RT * λ_rt[t] * eb_da_out[tmap[t]]
        lin_cost_dart_in = Δt_RT * λ_rt[t] * eb_da_in[tmap[t]]
        lin_cost_p_th = -Δt_RT * C_th_var * p_th[t]
        lin_cost_p_ch = -Δt_RT * VOM * p_ch[t]
        lin_cost_p_ds = -Δt_RT * VOM * p_ds[t]
        PSI.add_to_objective_invariant_expression!(container, lin_cost_rt_out)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_rt_in)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_dart_out)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_dart_in)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_p_th)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_p_ch)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_p_ds)
    end
    JuMP.@objective(model, MOI.MAX_SENSE, container.objective_function.invariant_terms)

    ###############################
    ######## Constraints ##########
    ###############################

    ## Read remaining variables
    # Internal Ancillary Services Bid RT
    sb_ru_rt_out = PSI.get_variable(container, RegUpRTBidOut(), PSY.HybridSystem)
    sb_ru_rt_in = PSI.get_variable(container, RegUpRTBidIn(), PSY.HybridSystem)
    sb_spin_rt_out = PSI.get_variable(container, SpinRTBidOut(), PSY.HybridSystem)
    sb_spin_rt_in = PSI.get_variable(container, SpinRTBidIn(), PSY.HybridSystem)
    sb_rd_rt_out = PSI.get_variable(container, RegDownRTBidOut(), PSY.HybridSystem)
    sb_rd_rt_in = PSI.get_variable(container, RegDownRTBidIn(), PSY.HybridSystem)
    # Internal Ancillary Services Bid Thermal
    sb_ru_th = PSI.get_variable(container, RegUpThermalBid(), PSY.HybridSystem)
    sb_spin_th = PSI.get_variable(container, SpinThermalBid(), PSY.HybridSystem)
    sb_rd_th = PSI.get_variable(container, RegDownThermalBid(), PSY.HybridSystem)
    # Internal Ancillary Services Bid Renewable
    sb_ru_re = PSI.get_variable(container, RegUpRenewableBid(), PSY.HybridSystem)
    sb_spin_re = PSI.get_variable(container, SpinRenewableBid(), PSY.HybridSystem)
    sb_rd_re = PSI.get_variable(container, RegDownRenewableBid(), PSY.HybridSystem)
    # Internal Ancillary Services Bid Charge Battery
    sb_ru_ch = PSI.get_variable(container, RegUpBatteryChargeBid(), PSY.HybridSystem)
    sb_spin_ch = PSI.get_variable(container, SpinBatteryChargeBid(), PSY.HybridSystem)
    sb_rd_ch = PSI.get_variable(container, RegDownBatteryChargeBid(), PSY.HybridSystem)
    # Internal Ancillary Services Bid Discharge Battery
    sb_ru_ds = PSI.get_variable(container, RegUpBatteryDischargeBid(), PSY.HybridSystem)
    sb_spin_ds = PSI.get_variable(container, SpinBatteryDischargeBid(), PSY.HybridSystem)
    sb_rd_ds = PSI.get_variable(container, RegDownBatteryDischargeBid(), PSY.HybridSystem)
    # RT Internal Asset Energy Bid
    eb_rt_th = PSI.get_variable(container, EnergyThermalBid(), PSY.HybridSystem)
    eb_rt_re = PSI.get_variable(container, EnergyRenewableBid(), PSY.HybridSystem)
    eb_rt_ch = PSI.get_variable(container, EnergyBatteryChargeBid(), PSY.HybridSystem)
    eb_rt_ds = PSI.get_variable(container, EnergyBatteryDischargeBid(), PSY.HybridSystem)

    ###################
    ### Upper Level ###
    ###################

    # Bid PCC Limits DA
    constraint_da_bid_up_out = PSI.add_constraints_container!(
        container,
        BidOutDAUpperLimit(),
        PSY.HybridSystem,
        T_da,
    )
    constraint_da_bid_up_in = PSI.add_constraints_container!(
        container,
        BidInDAUpperLimit(),
        PSY.HybridSystem,
        T_da,
    )
    constraint_da_bid_low_out = PSI.add_constraints_container!(
        container,
        BidOutDALowerLimit(),
        PSY.HybridSystem,
        T_da,
    )
    constraint_da_bid_low_in = PSI.add_constraints_container!(
        container,
        BidInDALowerLimit(),
        PSY.HybridSystem,
        T_da,
    )

    # Bid PCC Limits RT
    constraint_rt_bid_up_out = PSI.add_constraints_container!(
        container,
        BidOutRTUpperLimit(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_rt_bid_low_out = PSI.add_constraints_container!(
        container,
        BidOutRTLowerLimit(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_rt_bid_up_in = PSI.add_constraints_container!(
        container,
        BidInRTUpperLimit(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_rt_bid_low_in = PSI.add_constraints_container!(
        container,
        BidInRTLowerLimit(),
        PSY.HybridSystem,
        T_rt,
    )

    # Battery AS Coverage
    constraint_rd_charge_coverage = PSI.add_constraints_container!(
        container,
        RegDownBatteryChargeCoverage(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_ru_discharge_coverage = PSI.add_constraints_container!(
        container,
        RegUpBatteryDischargeCoverage(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_spin_discharge_coverage = PSI.add_constraints_container!(
        container,
        SpinBatteryDischargeCoverage(),
        PSY.HybridSystem,
        T_rt,
    )

    # Energy Bid Asset Balance
    constraint_energy_bid_asset_balance = PSI.add_constraints_container!(
        container,
        EnergyBidAssetBalance(),
        PSY.HybridSystem,
        T_rt,
    )

    # Ancillary Services Market Convergence
    constraint_regup_bid_convergence = PSI.add_constraints_container!(
        container,
        RegUpBidMarketConvergence(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_regdown_bid_convergence = PSI.add_constraints_container!(
        container,
        RegDownBidMarketConvergence(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_spin_bid_convergence = PSI.add_constraints_container!(
        container,
        SpinBidMarketConvergence(),
        PSY.HybridSystem,
        T_rt,
    )

    # Ancillary Services Bid Balance
    constraint_regup_bid_balance = PSI.add_constraints_container!(
        container,
        RegUpBidAssetBalance(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_regdown_bid_balance = PSI.add_constraints_container!(
        container,
        RegDownBidAssetBalance(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_spin_bid_balance = PSI.add_constraints_container!(
        container,
        SpinBidAssetBalance(),
        PSY.HybridSystem,
        T_rt,
    )

    # Thermal Bid Limits
    constraint_bid_up_thermal =
        PSI.add_constraints_container!(container, ThermalBidUp(), PSY.HybridSystem, T_rt)
    constraint_bid_down_thermal =
        PSI.add_constraints_container!(container, ThermalBidDown(), PSY.HybridSystem, T_rt)

    # Renewable Bid Limits
    constraint_bid_up_renewable =
        PSI.add_constraints_container!(container, RenewableBidUp(), PSY.HybridSystem, T_rt)
    constraint_bid_down_renewable = PSI.add_constraints_container!(
        container,
        RenewableBidDown(),
        PSY.HybridSystem,
        T_rt,
    )

    # Battery Bid Limits
    constraint_bid_up_charge = PSI.add_constraints_container!(
        container,
        BatteryChargeBidUp(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_bid_down_charge = PSI.add_constraints_container!(
        container,
        BatteryChargeBidDown(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_bid_up_discharge = PSI.add_constraints_container!(
        container,
        BatteryDischargeBidUp(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_bid_down_discharge = PSI.add_constraints_container!(
        container,
        BatteryDischargeBidDown(),
        PSY.HybridSystem,
        T_rt,
    )

    # Across Market Balance
    constraint_eb_out =
        PSI.add_constraints_container!(container, BidBalanceOut(), PSY.HybridSystem, T_rt)
    constraint_eb_in =
        PSI.add_constraints_container!(container, BidBalanceIn(), PSY.HybridSystem, T_rt)
    constraint_status_bid_in =
        PSI.add_constraints_container!(container, StatusInOn(), PSY.HybridSystem, T_rt)
    constraint_status_bid_out =
        PSI.add_constraints_container!(container, StatusOutOn(), PSY.HybridSystem, T_rt)

    ###################
    ### Lower Level ###
    ###################

    # Asset Balance
    constraint_balance = PSI.add_constraints_container!(
        container,
        EnergyAssetBalance(),
        PSY.HybridSystem,
        T_rt,
    )

    # Thermal
    constraint_thermal_on = PSI.add_constraints_container!(
        container,
        ThermalOnVariableUb(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_thermal_off = PSI.add_constraints_container!(
        container,
        ThermalOnVariableLb(),
        PSY.HybridSystem,
        T_rt,
    )

    # Battery
    constraint_battery_charging = PSI.add_constraints_container!(
        container,
        BatteryStatusChargeOn(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_battery_discharging = PSI.add_constraints_container!(
        container,
        BatteryStatusDischargeOn(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_battery_balance =
        PSI.add_constraints_container!(container, BatteryBalance(), PSY.HybridSystem, T_rt)
    constraint_cycling_charge =
        PSI.add_constraints_container!(container, CyclingCharge(), PSY.HybridSystem, 1)
    constraint_cycling_discharge =
        PSI.add_constraints_container!(container, CyclingDischarge(), PSY.HybridSystem, 1)

    ### Implement Constraints ###
    for t in T_da
        # DA Bid Limits
        constraint_da_bid_up_out[t] = JuMP.@constraint(
            model,
            eb_da_out[t] + sb_ru_da_out[t] + sb_spin_da_out[t] <= P_max_pcc
        )
        constraint_da_bid_up_in[t] =
            JuMP.@constraint(model, eb_da_in[t] + sb_rd_da_in[t] <= P_max_pcc)
        constraint_da_bid_low_out[t] =
            JuMP.@constraint(model, eb_da_out[t] - sb_rd_da_out[t] >= 0.0)
        constraint_da_bid_low_in[t] =
            JuMP.@constraint(model, eb_da_in[t] - sb_ru_da_in[t] - sb_spin_da_in[t] >= 0.0)
    end

    for t in T_rt
        # RT Bid Limits
        # t
        constraint_rt_bid_up_out[t] = JuMP.@constraint(
            model,
            eb_rt_out[t] + sb_ru_rt_out[t] + sb_spin_rt_out[t] <= P_max_pcc
        )
        constraint_rt_bid_up_in[t] =
            JuMP.@constraint(model, eb_rt_in[t] + sb_rd_rt_in[t] <= P_max_pcc)
        constraint_rt_bid_low_out[t] =
            JuMP.@constraint(model, eb_rt_out[t] - sb_rd_rt_out[t] >= 0.0)
        constraint_rt_bid_low_in[t] =
            JuMP.@constraint(model, eb_rt_in[t] - sb_ru_rt_in[t] - sb_spin_rt_in[t] >= 0.0)

        # Battery AS Coverage
        if t == 1
            constraint_rd_charge_coverage[t] =
                JuMP.@constraint(model, sb_rd_ch[t] * η_ch * N * Δt_RT <= E_max - E0)
            constraint_ru_discharge_coverage[t] =
                JuMP.@constraint(model, sb_ru_ds[t] * inv_η_ds * N * Δt_RT <= E0)
            constraint_spin_discharge_coverage[t] =
                JuMP.@constraint(model, sb_spin_ds[t] * inv_η_ds * N * Δt_RT <= E0)
        else
            constraint_rd_charge_coverage[t] = JuMP.@constraint(
                model,
                sb_rd_ch[t] * η_ch * N * Δt_RT <= E_max - e_st[t - 1]
            )
            constraint_ru_discharge_coverage[t] =
                JuMP.@constraint(model, sb_ru_ds[t] * inv_η_ds * N * Δt_RT <= e_st[t - 1])
            constraint_spin_discharge_coverage[t] =
                JuMP.@constraint(model, sb_spin_ds[t] * inv_η_ds * N * Δt_RT <= e_st[t - 1])
        end

        # RT Energy Market Internal Bid Balance
        constraint_energy_bid_asset_balance[t] = JuMP.@constraint(
            model,
            eb_rt_th[t] + eb_rt_re[t] + eb_rt_ds[t] - eb_rt_ch[t] - P_ld[t] - eb_rt_out[t] + eb_rt_in[t] == 0.0
        )

        # AS Market Convergence #
        constraint_regup_bid_convergence[t] = JuMP.@constraint(
            model,
            sb_ru_rt_out[t] + sb_ru_rt_in[t] - sb_ru_da_out[tmap[t]] -
            sb_ru_da_in[tmap[t]] == 0.0
        )
        constraint_regdown_bid_convergence[t] = JuMP.@constraint(
            model,
            sb_rd_rt_out[t] + sb_rd_rt_in[t] - sb_rd_da_out[tmap[t]] -
            sb_rd_da_in[tmap[t]] == 0.0
        )
        constraint_spin_bid_convergence[t] = JuMP.@constraint(
            model,
            sb_spin_rt_out[t] + sb_spin_rt_in[t] - sb_spin_da_out[tmap[t]] -
            sb_spin_da_in[tmap[t]] == 0.0
        )

        # AS Bid Balance #
        constraint_regup_bid_balance[t] = JuMP.@constraint(
            model,
            sb_ru_th[t] + sb_ru_re[t] + sb_ru_ch[t] + sb_ru_ds[t] - sb_ru_rt_out[t] -
            sb_ru_rt_in[t] >= 0.0
        )
        constraint_regdown_bid_balance[t] = JuMP.@constraint(
            model,
            sb_rd_th[t] + sb_rd_re[t] + sb_rd_ch[t] + sb_rd_ds[t] - sb_rd_rt_out[t] -
            sb_rd_rt_in[t] >= 0.0
        )
        constraint_spin_bid_balance[t] = JuMP.@constraint(
            model,
            sb_spin_th[t] + sb_spin_re[t] + sb_spin_ch[t] + sb_spin_ds[t] -
            sb_spin_rt_out[t] - sb_spin_rt_in[t] >= 0.0
        )

        # Thermal Bid Limits #
        constraint_bid_up_thermal[t] = JuMP.@constraint(
            model,
            eb_rt_th[t] + sb_ru_th[t] + sb_spin_th[t] <= on_th[tmap[t]] * P_max_th
        )
        constraint_bid_down_thermal[t] =
            JuMP.@constraint(model, eb_rt_th[t] - sb_rd_th[t] >= on_th[tmap[t]] * P_min_th)

        # Renewable Bid Limits #
        constraint_bid_up_renewable[t] = JuMP.@constraint(
            model,
            eb_rt_re[t] + sb_ru_re[t] + sb_spin_re[t] <= P_re_star[t]
        )
        constraint_bid_down_renewable[t] =
            JuMP.@constraint(model, eb_rt_re[t] - sb_rd_re[t] >= 0.0)

        # Battery Charge Bid Limits #
        constraint_bid_up_charge[t] = JuMP.@constraint(
            model,
            eb_rt_ch[t] + sb_ru_ch[t] + sb_spin_ch[t] <= (1 - status_st[t]) * P_ch_max
        )
        constraint_bid_down_charge[t] =
            JuMP.@constraint(model, eb_rt_ch[t] - sb_rd_ch[t] >= 0.0)

        # Battery Disharge Bid Limits #
        constraint_bid_up_discharge[t] =
            JuMP.@constraint(model, eb_rt_ds[t] + sb_rd_ds[t] <= status_st[t] * P_ds_max)
        constraint_bid_down_discharge[t] =
            JuMP.@constraint(model, eb_rt_ds[t] - sb_ru_ds[t] - sb_spin_ds[t] >= 0.0)

        # Market Constraint Bids in/out
        constraint_eb_out[t] = JuMP.@constraint(
            model,
            eb_rt_out[t] + R_up * sb_ru_rt_out[t] + R_spin * sb_spin_rt_out[t] -
            R_dn * sb_rd_rt_out[t] == p_out[t]
        )
        constraint_eb_in[t] = JuMP.@constraint(
            model,
            eb_rt_in[t] + R_dn * sb_rd_rt_in[t] - R_up * sb_ru_rt_in[t] -
            R_spin * sb_spin_rt_in[t] == p_in[t]
        )
        # Status Bids
        constraint_status_bid_in[t] =
            JuMP.@constraint(model, (1.0 - status[t]) * P_max_pcc >= p_in[t])
        constraint_status_bid_out[t] =
            JuMP.@constraint(model, status[t] * P_max_pcc >= p_out[t])
        # Power Balance
        constraint_balance[t] = JuMP.@constraint(
            model,
            p_th[t] + p_re[t] + p_ds[t] - p_ch[t] - P_ld[t] - p_out[t] + p_in[t] == 0.0
        )
        # Thermal Status
        constraint_thermal_on[t] =
            JuMP.@constraint(model, p_th[t] <= on_th[tmap[t]] * P_max_th)
        constraint_thermal_off[t] =
            JuMP.@constraint(model, p_th[t] >= on_th[tmap[t]] * P_min_th)
        # Battery Constraints
        constraint_battery_charging[t] =
            JuMP.@constraint(model, p_ch[t] <= (1.0 - status_st[t]) * P_ch_max)
        constraint_battery_discharging[t] =
            JuMP.@constraint(model, p_ds[t] <= status_st[t] * P_ds_max)
        # Battery Energy Constraints
        if t == 1
            constraint_battery_balance[t] = JuMP.@constraint(
                model,
                E0 + Δt_RT * (p_ch[t] * η_ch - p_ds[t] * inv_η_ds) == e_st[t]
            )
        else
            constraint_battery_balance[t] = JuMP.@constraint(
                model,
                e_st[t - 1] + Δt_RT * (p_ch[t] * η_ch - p_ds[t] * inv_η_ds) == e_st[t]
            )
        end
    end
    # Cycling Constraints
    constraint_cycling_charge[1] =
        JuMP.@constraint(model, inv_η_ds * Δt_RT * sum(p_ds) <= Cycles * E_max)
    constraint_cycling_discharge[1] =
        JuMP.@constraint(model, η_ch * Δt_RT * sum(p_ch) <= Cycles * E_max)

    # Fix Thermal Variable
    JuMP.fix.(on_th, 0, force=true)
    PSI.serialize_metadata!(container, mktempdir(cleanup=true))
    return
end
=#
