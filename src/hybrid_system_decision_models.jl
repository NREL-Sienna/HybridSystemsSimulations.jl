PSI.get_variable_binary(
    ::PSI.VariableType,
    t::Type{PSY.HybridSystem},
    ::HybridDecisionProblem,
) = false
PSI.get_variable_binary(
    ::BatteryStatus,
    t::Type{PSY.HybridSystem},
    ::HybridDecisionProblem,
) = true
PSI.get_variable_binary(
    ::PSI.OnVariable,
    t::Type{PSY.HybridSystem},
    ::HybridDecisionProblem,
) = true
PSI.get_variable_binary(
    ::PSI.ReservationVariable,
    t::Type{PSY.HybridSystem},
    ::HybridDecisionProblem,
) = true

# Defined to avoid ambiguity
PSI.get_variable_binary(
    ::PSI.ActivePowerOutVariable,
    t::Type{PSY.HybridSystem},
    ::HybridDecisionProblem,
) = false
PSI.get_variable_binary(
    ::PSI.ActivePowerInVariable,
    t::Type{PSY.HybridSystem},
    ::HybridDecisionProblem,
) = false
PSI.get_variable_binary(
    ::ThermalPower,
    t::Type{PSY.HybridSystem},
    ::HybridDecisionProblem,
) = false
PSI.get_variable_binary(
    ::RenewablePower,
    t::Type{PSY.HybridSystem},
    ::HybridDecisionProblem,
) = false
PSI.get_variable_binary(
    ::BatteryCharge,
    t::Type{PSY.HybridSystem},
    ::HybridDecisionProblem,
) = false
PSI.get_variable_binary(
    ::BatteryDischarge,
    t::Type{PSY.HybridSystem},
    ::HybridDecisionProblem,
) = false
PSI.get_variable_binary(
    ::PSI.EnergyVariable,
    t::Type{PSY.HybridSystem},
    ::HybridDecisionProblem,
) = false

PSI.get_variable_binary(
    ::EnergyRTBidOut,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false

PSI.get_variable_binary(
    ::EnergyRTBidIn,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false

PSI.get_variable_binary(
    ::MerchantModelDualVariable,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false

PSI.get_variable_binary(
    ::MerchantModelComplementarySlackVariable,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false

# UBs and LowerBounds Decision Problem
PSI.get_variable_lower_bound(
    ::EnergyDABidOut,
    d::PSY.HybridSystem,
    ::HybridDecisionProblem,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyDABidOut,
    d::PSY.HybridSystem,
    ::HybridDecisionProblem,
) = PSY.get_output_active_power_limits(d).max

PSI.get_variable_lower_bound(
    ::EnergyDABidIn,
    d::PSY.HybridSystem,
    ::HybridDecisionProblem,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyDABidIn,
    d::PSY.HybridSystem,
    ::HybridDecisionProblem,
) = PSY.get_output_active_power_limits(d).max

PSI.get_variable_lower_bound(
    ::EnergyRTBidOut,
    d::PSY.HybridSystem,
    ::HybridDecisionProblem,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyRTBidOut,
    d::PSY.HybridSystem,
    ::HybridDecisionProblem,
) = PSY.get_output_active_power_limits(d).max

PSI.get_variable_lower_bound(
    ::EnergyRTBidIn,
    d::PSY.HybridSystem,
    ::HybridDecisionProblem,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyRTBidIn,
    d::PSY.HybridSystem,
    ::HybridDecisionProblem,
) = PSY.get_output_active_power_limits(d).max

# UBs and LBs for Formulation
PSI.get_variable_lower_bound(
    ::EnergyDABidOut,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyDABidOut,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_output_active_power_limits(d).max

PSI.get_variable_lower_bound(
    ::EnergyDABidIn,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyDABidIn,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_output_active_power_limits(d).max

PSI.get_variable_lower_bound(
    ::EnergyRTBidOut,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyRTBidOut,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_output_active_power_limits(d).max

PSI.get_variable_lower_bound(
    ::EnergyRTBidIn,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyRTBidIn,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_output_active_power_limits(d).max

PSI.get_variable_lower_bound(
    ::MerchantModelDualVariable,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = 0.0

function _get_row_val(df, row_name)
    return df[only(findall(==(row_name), df.ParamName)), :]["Value"]
end

###################################################################
######################### Variables ###############################
###################################################################

function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::Vector{PSY.HybridSystem},
    formulation::U,
) where {T <: Union{EnergyDABidOut, EnergyDABidIn}, U <: AbstractHybridFormulation}
    @assert !isempty(devices)
    time_steps = PSY.get_ext(first(devices))["T_da"]
    variable = PSI.add_variable_container!(
        container,
        T(),
        PSY.HybridSystem,
        [PSY.get_name(d) for d in devices],
        time_steps,
    )

    for t in time_steps, d in devices
        name = PSY.get_name(d)
        variable[name, t] = JuMP.@variable(
            PSI.get_jump_model(container),
            base_name = "$(T)_HybridSystem_{$(name), $(t)}",
        )
        ub = PSI.get_variable_upper_bound(T(), d, formulation)
        ub !== nothing && JuMP.set_upper_bound(variable[name, t], ub)

        lb = PSI.get_variable_lower_bound(T(), d, formulation)
        lb !== nothing && JuMP.set_lower_bound(variable[name, t], lb)
    end
    return
end

function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::Vector{PSY.HybridSystem},
    formulation::U,
) where {
    T <: PSI.OnVariable,
    U <: Union{MerchantHybridEnergyCase, MerchantModelWithReserves},
}
    @assert !isempty(devices)
    time_steps = PSY.get_ext(first(devices))["T_da"]
    variable = PSI.add_variable_container!(
        container,
        T(),
        PSY.HybridSystem,
        [PSY.get_name(d) for d in devices],
        time_steps,
    )

    for t in time_steps, d in devices
        name = PSY.get_name(d)
        variable[name, t] = JuMP.@variable(
            PSI.get_jump_model(container),
            base_name = "$(T)_HybridSystem_{$(name), $(t)}",
            binary = true
        )
    end
    return
end

# AS Total Bid for hybrid
function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{W},
    devices::Vector{PSY.HybridSystem},
    formulation::MerchantModelWithReserves,
) where {W <: Union{BidReserveVariableOut, BidReserveVariableIn}}
    @assert !isempty(devices)
    time_steps = PSY.get_ext(first(devices))["T_da"]
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

# AS Bid for each component and product
function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{W},
    devices::Union{Vector{U}, IS.FlattenIteratorWrapper{U}},
    formulation::MerchantHybridCooptimizerCase,
) where {U <: PSY.HybridSystem, W <: ComponentReserveVariableType}
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

function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{W},
    devices::Union{Vector{U}, IS.FlattenIteratorWrapper{U}},
    formulation::MerchantModelWithReserves,
) where {
    U <: PSY.HybridSystem,
    W <: Union{ComplementarySlackVarCyclingCharge, ComplementarySlackVarCyclingDischarge},
}
    variable = PSI.add_variable_container!(container, W(), U, PSY.get_name.(devices))

    for d in devices
        name = PSY.get_name(d)
        variable[name] = JuMP.@variable(
            PSI.get_jump_model(container),
            base_name = "$(W)_{$(PSY.get_name(d))}",
        )
    end
    return
end

function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{W},
    devices::Union{Vector{U}, IS.FlattenIteratorWrapper{U}},
    formulation::MerchantModelWithReserves,
) where {U <: PSY.HybridSystem, W <: Union{κStCh, κStDs}}
    variable = PSI.add_variable_container!(container, W(), U, PSY.get_name.(devices))

    for d in devices
        name = PSY.get_name(d)
        variable[name] = JuMP.@variable(
            PSI.get_jump_model(container),
            base_name = "$(W)_{$(PSY.get_name(d))}",
        )
    end
    return
end

###################################################################
######################## Parameters ###############################
###################################################################

function _add_time_series_parameters(
    container::PSI.OptimizationContainer,
    ts_name::String,
    param,
    devices::Vector{PSY.HybridSystem},
)
    ts_name
    ts_type = PSI.get_default_time_series_type(container)
    time_steps = PSI.get_time_steps(container)

    device_names = String[]
    initial_values = Dict{String, AbstractArray}()
    for device in devices
        push!(device_names, PSY.get_name(device))
        ts_uuid = PSI.get_time_series_uuid(ts_type, device, ts_name)
        if !(ts_uuid in keys(initial_values))
            initial_values[ts_uuid] =
                PSI.get_time_series_initial_values!(container, ts_type, device, ts_name)
        end
    end

    param_container = PSI.add_param_container!(
        container,
        param,
        PSY.HybridSystem,
        ts_type,
        ts_name,
        collect(keys(initial_values)),
        device_names,
        time_steps,
    )
    jump_model = PSI.get_jump_model(container)

    for (ts_uuid, ts_values) in initial_values
        for step in time_steps
            PSI.set_parameter!(param_container, jump_model, ts_values[step], ts_uuid, step)
        end
    end

    for device in devices
        name = PSY.get_name(device)
        multiplier = PSY.get_max_active_power(device.renewable_unit)
        for step in time_steps
            PSI.set_multiplier!(param_container, multiplier, name, step)
        end
        PSI.add_component_name!(
            PSI.get_attributes(param_container),
            name,
            PSI.get_time_series_uuid(ts_type, device, ts_name),
        )
    end
    return
end

# Multipliers consider that the objective function is a Maximization problem
# But the default direction in PSI is Min.
_get_multiplier(::Type{EnergyDABidOut}, ::DayAheadEnergyPrice) = -1.0
_get_multiplier(::Type{EnergyDABidIn}, ::DayAheadEnergyPrice) = 1.0
_get_multiplier(::Type{EnergyRTBidOut}, ::RealTimeEnergyPrice) = -1.0
_get_multiplier(::Type{EnergyRTBidIn}, ::RealTimeEnergyPrice) = 1.0
_get_multiplier(::Type{EnergyDABidOut}, ::RealTimeEnergyPrice) = 1.0
_get_multiplier(::Type{EnergyDABidIn}, ::RealTimeEnergyPrice) = -1.0
_get_multiplier(::Type{BidReserveVariableOut}, ::AncillaryServicePrice) = 1.0
_get_multiplier(::Type{BidReserveVariableIn}, ::AncillaryServicePrice) = 1.0

# DA and RT Prices
function _add_price_time_series_parameters(
    container::PSI.OptimizationContainer,
    param::Union{RealTimeEnergyPrice, DayAheadEnergyPrice},
    ts_key::String,
    devices::Vector{PSY.HybridSystem},
    time_step_string::String,
    vars::Vector,
)
    time_steps = 1:PSY.get_ext(first(devices))[time_step_string]
    device_names = PSY.get_name.(devices)
    jump_model = PSI.get_jump_model(container)

    for var in vars
        param_container = PSI.add_param_container!(
            container,
            param,
            PSY.HybridSystem,
            var,
            PSI.SOSStatusVariable.NO_VARIABLE,
            false,
            Float64,
            device_names,
            time_steps;
            meta="$var",
        )

        for device in devices
            λ = PSY.get_ext(device)[ts_key]
            Bus_name = PSY.get_name(PSY.get_bus(device))
            price_value = λ[!, Bus_name]
            name = PSY.get_name(device)
            for step in time_steps
                PSI.set_parameter!(
                    param_container,
                    jump_model,
                    price_value[step],
                    name,
                    step,
                )
                PSI.set_multiplier!(
                    param_container,
                    _get_multiplier(var, param),
                    name,
                    step,
                )
            end
        end
    end
    return
end

# Ancillary Service Prices
function _add_price_time_series_parameters(
    container::PSI.OptimizationContainer,
    param::AncillaryServicePrice,
    ts_key::String,
    devices::Vector{PSY.HybridSystem},
    time_step_string::String,
    vars::Vector,
)
    time_steps = 1:PSY.get_ext(first(devices))[time_step_string]
    device_names = PSY.get_name.(devices)
    jump_model = PSI.get_jump_model(container)

    services = Set()
    for d in devices
        union!(services, PSY.get_services(d))
    end
    for var in vars
        for service in services
            service_name = PSY.get_name(service)
            param_container = PSI.add_param_container!(
                container,
                param,
                PSY.HybridSystem,
                var,
                PSI.SOSStatusVariable.NO_VARIABLE,
                false,
                Float64,
                device_names,
                time_steps;
                meta="$(var)_$(service_name)",
            )

            for device in devices
                ts_key_service = "$(ts_key)_$(service_name)"
                λ = PSY.get_ext(device)[ts_key_service]
                Bus_name = PSY.get_name(PSY.get_bus(device))
                price_value = λ[!, Bus_name]
                name = PSY.get_name(device)
                for step in time_steps
                    PSI.set_parameter!(
                        param_container,
                        jump_model,
                        price_value[step],
                        name,
                        step,
                    )
                    PSI.set_multiplier!(
                        param_container,
                        _get_multiplier(var, param),
                        name,
                        step,
                    )
                end
            end
        end
    end
    return
end

function add_time_series_parameters!(
    container::PSI.OptimizationContainer,
    param::RenewablePowerTimeSeries,
    devices::Vector{PSY.HybridSystem},
    ts_name="RenewableDispatch__max_active_power",
)
    _add_time_series_parameters(container, ts_name, param, devices)
end

function add_time_series_parameters!(
    container::PSI.OptimizationContainer,
    param::ElectricLoadTimeSeries,
    devices::Vector{PSY.HybridSystem},
    ts_name="PowerLoad__max_active_power",
)
    _add_time_series_parameters(container, ts_name, param, devices)
    return
end

function PSI.add_parameters!(
    container::PSI.OptimizationContainer,
    param::T,
    devices::Vector{PSY.HybridSystem},
    ::W,
) where {
    T <: Union{DayAheadEnergyPrice, RealTimeEnergyPrice, AncillaryServicePrice},
    W <: Union{MerchantModelEnergyOnly, MerchantModelWithReserves},
}
    add_time_series_parameters!(container, param, devices)
end

function add_time_series_parameters!(
    container::PSI.OptimizationContainer,
    param::DayAheadEnergyPrice,
    devices::Vector{PSY.HybridSystem},
)
    ts_key = "λ_da_df"
    vars = [EnergyDABidOut, EnergyDABidIn]
    _add_price_time_series_parameters(container, param, ts_key, devices, "horizon_DA", vars)
    return
end

function add_time_series_parameters!(
    container::PSI.OptimizationContainer,
    param::RealTimeEnergyPrice,
    devices::Vector{PSY.HybridSystem},
)
    ts_key = "λ_rt_df"
    vars = [EnergyDABidOut, EnergyDABidIn, EnergyRTBidOut, EnergyRTBidIn]
    _add_price_time_series_parameters(container, param, ts_key, devices, "horizon_RT", vars)
    return
end

function add_time_series_parameters!(
    container::PSI.OptimizationContainer,
    param::AncillaryServicePrice,
    devices::Vector{PSY.HybridSystem},
)
    ts_key = "λ"
    vars = [BidReserveVariableOut, BidReserveVariableIn]
    _add_price_time_series_parameters(container, param, ts_key, devices, "horizon_DA", vars)
    return
end

function PSI.update_parameter_values!(
    model::PSI.DecisionModel{T},
    key::PSI.ParameterKey{U, PSY.HybridSystem},
    ::PSI.DatasetContainer{PSI.InMemoryDataset},
) where {T <: HybridDecisionProblem, U <: Union{DayAheadEnergyPrice, RealTimeEnergyPrice}}
    container = PSI.get_optimization_container(model)
    @assert !PSI.is_synchronized(container)
    _update_parameter_values!(model, key)
    return
end

function _update_parameter_values!(
    model::PSI.DecisionModel{T},
    key::PSI.ParameterKey{DayAheadEnergyPrice, PSY.HybridSystem},
) where {T <: HybridDecisionProblem}
    initial_forecast_time = PSI.get_current_time(model)
    container = PSI.get_optimization_container(model)
    parameter_array = PSI.get_parameter_array(container, key)
    parameter_multiplier = PSI.get_parameter_multiplier_array(container, key)
    attributes = PSI.get_parameter_attributes(container, key)
    components = PSI.get_available_components(PSY.HybridSystem, PSI.get_system(model))
    resolution = PSI.get_resolution(container)
    dt = Dates.value(Dates.Second(resolution)) / PSI.SECONDS_IN_HOUR
    for component in components
        ext = PSY.get_ext(component)
        horizon = ext["horizon_DA"]
        bus_name = PSY.get_name(PSY.get_bus(component))
        ix = PSI.find_timestamp_index(ext["λ_da_df"][!, "DateTime"], initial_forecast_time)
        λ = ext["λ_da_df"][!, bus_name][ix:(ix + horizon - 1)]
        name = PSY.get_name(component)
        for (t, value) in enumerate(λ)
            # Since the DA variables are hourly, this will revert the dt multiplication
            PSI._set_param_value!(parameter_array, value * dt * 100.0, name, t)
            PSI.update_variable_cost!(
                container,
                parameter_array,
                parameter_multiplier,
                attributes,
                component,
                t,
            )
        end
    end
    return
end

# The definition of these two methods is required because of the two resolutions used
# in the model. Updating the real-time price requires using the mapping. Normally we don't
# want to expose this level of detail to users wanting to make extensions
function _update_parameter_values!(
    model::PSI.DecisionModel{T},
    key::PSI.ParameterKey{RealTimeEnergyPrice, PSY.HybridSystem},
) where {T <: HybridDecisionProblem}
    initial_forecast_time = PSI.get_current_time(model)
    container = PSI.get_optimization_container(model)
    resolution = PSI.get_resolution(container)
    dt = Dates.value(Dates.Second(resolution)) / PSI.SECONDS_IN_HOUR
    parameter_array = PSI.get_parameter_array(container, key)
    attributes = PSI.get_parameter_attributes(container, key)
    components = PSI.get_available_components(PSY.HybridSystem, PSI.get_system(model))
    variable =
        PSI.get_variable(container, PSI.get_variable_type(attributes)(), PSY.HybridSystem)
    @show parameter_multiplier = PSI.get_parameter_multiplier_array(container, key)
    for component in components
        ext = PSY.get_ext(component)
        tmap = ext["tmap"]
        horizon = ext["horizon_RT"]
        bus_name = PSY.get_name(PSY.get_bus(component))
        ix = PSI.find_timestamp_index(ext["λ_rt_df"][!, "DateTime"], initial_forecast_time)
        λ = ext["λ_rt_df"][!, bus_name][ix:(ix + horizon - 1)]
        name = PSY.get_name(component)
        for (t, value) in enumerate(λ)
            mul_ = parameter_multiplier[name, t] * 100.0
            PSI._set_param_value!(parameter_array, value, name, t)
            if PSI.get_variable_type(attributes) ∈ (EnergyDABidOut, EnergyDABidIn)
                hy_cost = variable[name, tmap[t]] * value * dt * mul_
            else
                hy_cost = variable[name, t] * value * dt * mul_
            end
            PSI.add_to_objective_variant_expression!(container, hy_cost)
            PSI.set_expression!(
                container,
                PSI.ProductionCostExpression,
                hy_cost,
                component,
                t,
            )
        end
    end
    return
end

###################################################################
######################### Constraints #############################
###################################################################

# Day-Ahead Out Bid PCC Range Limits
function add_constraints_dayaheadlimit_out_withreserves!(
    container::PSI.OptimizationContainer,
    T::Type{<:DayAheadBidOutRangeLimit},
    devices::U,
    ::W,
    time_steps::UnitRange{Int64},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    names = [PSY.get_name(d) for d in devices]
    bid_out = PSI.get_variable(container, EnergyDABidOut(), D)
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
            bid_out[ci_name, t] + res_out_up[ci_name, t] <= max_limit
        )
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            bid_out[ci_name, t] - res_out_down[ci_name, t] >= 0.0
        )
    end
    return
end

# Day-Ahead In Bid PCC Range Limits
function add_constraints_dayaheadlimit_in_withreserves!(
    container::PSI.OptimizationContainer,
    T::Type{<:DayAheadBidInRangeLimit},
    devices::U,
    ::W,
    time_steps::UnitRange{Int64},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    names = [PSY.get_name(d) for d in devices]
    bid_in = PSI.get_variable(container, EnergyDABidIn(), D)
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
            bid_in[ci_name, t] + res_in_down[ci_name, t] <= max_limit
        )
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            bid_in[ci_name, t] - res_in_up[ci_name, t] >= 0.0
        )
    end
    return
end

# Real-Time Out Bid PCC Range Limits
function add_constraints_realtimelimit_out_withreserves!(
    container::PSI.OptimizationContainer,
    T::Type{<:RealTimeBidOutRangeLimit},
    devices::U,
    ::W,
    time_steps::UnitRange{Int64},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    names = [PSY.get_name(d) for d in devices]
    bid_out = PSI.get_variable(container, EnergyRTBidOut(), D)
    res_out_up = PSI.get_expression(container, TotalReserveOutUpExpression(), D)
    res_out_down = PSI.get_expression(container, TotalReserveOutDownExpression(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")
    con_lb = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="lb")

    for device in devices, t in time_steps
        tmap = PSY.get_ext(device)["tmap"]
        ci_name = PSY.get_name(device)
        max_limit = PSI.get_variable_upper_bound(PSI.ActivePowerOutVariable(), device, W())
        @assert max_limit !== nothing ci_name
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            bid_out[ci_name, t] + res_out_up[ci_name, tmap[t]] <= max_limit
        )
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            bid_out[ci_name, t] - res_out_down[ci_name, tmap[t]] >= 0.0
        )
    end
    return
end

# Day-Ahead In Bid PCC Range Limits
function add_constraints_realtimelimit_in_withreserves!(
    container::PSI.OptimizationContainer,
    T::Type{<:RealTimeBidInRangeLimit},
    devices::U,
    ::W,
    time_steps::UnitRange{Int64},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    names = [PSY.get_name(d) for d in devices]
    bid_in = PSI.get_variable(container, EnergyRTBidIn(), D)
    res_in_up = PSI.get_expression(container, TotalReserveInUpExpression(), D)
    res_in_down = PSI.get_expression(container, TotalReserveInDownExpression(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")
    con_lb = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="lb")

    for device in devices, t in time_steps
        tmap = PSY.get_ext(device)["tmap"]
        ci_name = PSY.get_name(device)
        max_limit = PSI.get_variable_upper_bound(PSI.ActivePowerInVariable(), device, W())
        @assert max_limit !== nothing ci_name
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            bid_in[ci_name, t] + res_in_down[ci_name, tmap[t]] <= max_limit
        )
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            bid_in[ci_name, t] - res_in_up[ci_name, tmap[t]] >= 0.0
        )
    end
    return
end

# Thermal Reserve Limit with Merchant Model
function _add_thermallimit_withreserves!(
    container::PSI.OptimizationContainer,
    T::Type{<:ThermalReserveLimit},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, PSI.OnVariable(), D)
    p_th = PSI.get_variable(container, ThermalPower(), D)
    reg_th_up = PSI.get_expression(container, ThermalReserveUpExpression(), D)
    reg_th_dn = PSI.get_expression(container, ThermalReserveDownExpression(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")
    con_lb = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="lb")

    for device in devices, t in time_steps
        tmap = PSY.get_ext(device)["tmap"]
        ci_name = PSY.get_name(device)
        min_limit, max_limit = PSY.get_active_power_limits(PSY.get_thermal_unit(device))
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_th[ci_name, t] + reg_th_up[ci_name, t] <= max_limit * varon[ci_name, tmap[t]]
        )
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_th[ci_name, t] - reg_th_dn[ci_name, t] >= min_limit * varon[ci_name, tmap[t]]
        )
    end
end

# Thermal Reserve Limit with Reserve Model
function _add_constraints_thermalon_variableon!(
    container::PSI.OptimizationContainer,
    T::Type{ThermalOnVariableUb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, PSI.OnVariable(), D)
    p_th = PSI.get_variable(container, ThermalPower(), D)
    con_ub = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="ub")

    for device in devices, t in time_steps
        tmap = PSY.get_ext(device)["tmap"]
        ci_name = PSY.get_name(device)
        max_limit = PSY.get_active_power_limits(PSY.get_thermal_unit(device)).max
        con_ub[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            p_th[ci_name, t] <= max_limit * varon[ci_name, tmap[t]]
        )
    end
    return
end

# ThermalOn Variable OFF for Merchant Model
function _add_constraints_thermalon_variableoff!(
    container::PSI.OptimizationContainer,
    T::Type{<:ThermalOnVariableLb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    varon = PSI.get_variable(container, PSI.OnVariable(), D)
    p_th = PSI.get_variable(container, ThermalPower(), D)
    con_lb = PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="lb")

    for device in devices, t in time_steps
        tmap = PSY.get_ext(device)["tmap"]
        ci_name = PSY.get_name(device)
        min_limit = PSY.get_active_power_limits(PSY.get_thermal_unit(device)).min
        con_lb[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            min_limit * varon[ci_name, tmap[t]] <= p_th[ci_name, t]
        )
    end
    return
end

# Energy Bid Balance in RT
function _add_constraints_energybidassetbalance!(
    container::PSI.OptimizationContainer,
    T::Type{<:EnergyBidAssetBalance},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: AbstractHybridFormulation,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    bid_out = PSI.get_variable(container, EnergyRTBidOut(), D)
    bid_in = PSI.get_variable(container, EnergyRTBidIn(), D)
    con_bal = PSI.add_constraints_container!(container, T(), D, names, time_steps)

    # Make Expression for this balance
    for device in devices
        ci_name = PSY.get_name(device)
        vars_pos = Set{JUMP_SET_TYPE}()
        vars_neg = Set{JUMP_SET_TYPE}()
        load_set = Set()

        if !isnothing(PSY.get_thermal_unit(device))
            bid_th = PSI.get_variable(container, EnergyThermalBid(), D)
            push!(vars_pos, bid_th[ci_name, :])
        end
        if !isnothing(PSY.get_renewable_unit(device))
            bid_re = PSI.get_variable(container, EnergyRenewableBid(), D)
            push!(vars_pos, bid_re[ci_name, :])
        end
        if !isnothing(PSY.get_storage(device))
            bid_ch = PSI.get_variable(container, EnergyBatteryChargeBid(), D)
            bid_ds = PSI.get_variable(container, EnergyBatteryDischargeBid(), D)
            push!(vars_pos, bid_ds[ci_name, :])
            push!(vars_neg, bid_ch[ci_name, :])
        end
        if !isnothing(PSY.get_electric_load(device))
            P = ElectricLoadTimeSeries
            param_container = PSI.get_parameter(container, P(), D)
            param = PSI.get_parameter_column_refs(param_container, ci_name).data
            multiplier = PSY.get_max_active_power(PSY.get_electric_load(device))
            push!(load_set, param * multiplier)
        end
        for t in time_steps
            total_power = -bid_out[ci_name, t] + bid_in[ci_name, t]
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

# Product Ancillary Service Balance
function _add_constraints_reservebalance!(
    container::PSI.OptimizationContainer,
    T::Type{<:ReserveBalance},
    devices::U,
    service::V,
    ::W,
    time_steps::UnitRange{Int64},
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    V <: PSY.Reserve,
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    service_name = PSY.get_name(service)
    res_out = PSI.get_variable(container, BidReserveVariableOut(), V, service_name)
    res_in = PSI.get_variable(container, BidReserveVariableIn(), V, service_name)
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
        tmap = PSY.get_ext(device)["tmap"]
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
            total_reserve = -res_out[ci_name, tmap[t]] - res_in[ci_name, tmap[t]]
            for vp in vars_pos
                JuMP.add_to_expression!(total_reserve, vp[t])
            end
            con[ci_name, t] =
                JuMP.@constraint(PSI.get_jump_model(container), total_reserve == 0.0)
        end
    end
    return
end

# Market Out Convergence
function _add_constraints_out_marketconvergence!(
    container::PSI.OptimizationContainer,
    T::Type{<:MarketOutConvergence},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    bid_out = PSI.get_variable(container, EnergyRTBidOut(), D)
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), D)
    res_out_up = PSI.get_expression(container, ServedReserveOutUpExpression(), D)
    res_out_down = PSI.get_expression(container, ServedReserveOutDownExpression(), D)
    con = PSI.add_constraints_container!(container, T(), D, names, time_steps)

    for device in devices, t in time_steps
        tmap = PSY.get_ext(device)["tmap"]
        ci_name = PSY.get_name(device)
        con[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            bid_out[ci_name, t] + res_out_up[ci_name, tmap[t]] -
            res_out_down[ci_name, tmap[t]] == p_out[ci_name, t]
        )
    end
    return
end

function _add_constraints_in_marketconvergence!(
    container::PSI.OptimizationContainer,
    T::Type{<:MarketInConvergence},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    bid_in = PSI.get_variable(container, EnergyRTBidIn(), D)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), D)
    res_in_up = PSI.get_expression(container, ServedReserveInUpExpression(), D)
    res_in_down = PSI.get_expression(container, ServedReserveInDownExpression(), D)
    con = PSI.add_constraints_container!(container, T(), D, names, time_steps)

    for device in devices, t in time_steps
        tmap = PSY.get_ext(device)["tmap"]
        ci_name = PSY.get_name(device)
        con[ci_name, t] = JuMP.@constraint(
            PSI.get_jump_model(container),
            bid_in[ci_name, t] + res_in_down[ci_name, tmap[t]] -
            res_in_up[ci_name, tmap[t]] == p_in[ci_name, t]
        )
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{OptConditionThermalPower},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    con = PSI.add_constraints_container!(container, T(), D, names, time_steps)
    λUb_var = PSI.get_variable(container, λUb(), D)
    λLb_var = PSI.get_variable(container, λLb(), D)
    μThUb_var = PSI.get_variable(container, μThUb(), D)
    μThLb_var = PSI.get_variable(container, μThLb(), D)
    jm = PSI.get_jump_model(container)
    for dev in devices
        n = PSY.get_name(dev)
        t_gen = dev.thermal_unit
        three_cost = PSY.get_operation_cost(t_gen)
        first_part = three_cost.variable[1]
        second_part = three_cost.variable[2]
        slope = (second_part[1] - first_part[1]) / (second_part[2] - first_part[2]) # $/MWh
        C_th_var = slope * 100.0 # Multiply by 100 to transform to $/pu
        for t in time_steps
            # Written to match latex model
            con[n, t] = JuMP.@constraint(
                jm,
                C_th_var - λUb_var[n, t] + λLb_var[n, t] - μThUb_var[n, t] +
                μThLb_var[n, t] == 0.0
            )
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{OptConditionRenewablePower},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    con = PSI.add_constraints_container!(container, T(), D, names, time_steps)
    λUb_var = PSI.get_variable(container, λUb(), D)
    λLb_var = PSI.get_variable(container, λLb(), D)
    μReUb_var = PSI.get_variable(container, μReUb(), D)
    μReLb_var = PSI.get_variable(container, μReLb(), D)
    jm = PSI.get_jump_model(container)
    for n in names, t in time_steps
        # Written to match latex model
        con[n, t] = JuMP.@constraint(
            jm,
            -λUb_var[n, t] + λLb_var[n, t] - μReUb_var[n, t] + μReLb_var[n, t] == 0.0
        )
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{OptConditionBatteryCharge},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    Δt_RT = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    con = PSI.add_constraints_container!(container, T(), D, names, time_steps)
    λUb_var = PSI.get_variable(container, λUb(), D)
    λLb_var = PSI.get_variable(container, λLb(), D)
    μChUb_var = PSI.get_variable(container, μChUb(), D)
    μChLb_var = PSI.get_variable(container, μChLb(), D)
    γStBalLb_var = PSI.get_variable(container, γStBalLb(), D)
    γStBalUb_var = PSI.get_variable(container, γStBalUb(), D)
    κStCh_var = PSI.get_variable(container, κStCh(), D)

    jm = PSI.get_jump_model(container)
    for dev in devices
        n = PSY.get_name(dev)
        storage = PSY.get_storage(dev)
        VOM = storage.operation_cost.variable.cost
        η_ch = storage.efficiency.in * Δt_RT
        for t in time_steps
            con[n, t] = JuMP.@constraint(
                jm,
                Δt_RT * VOM + λUb_var[n, t] - λLb_var[n, t] - μChUb_var[n, t] +
                μChLb_var[n, t] +
                η_ch * (-γStBalUb_var[n, t] + γStBalLb_var[n, t] - κStCh_var[n]) == 0.0
            )
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{OptConditionEnergyVariable},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    con = PSI.add_constraints_container!(container, T(), D, names, time_steps)
    νStUb_var = PSI.get_variable(container, νStUb(), D)
    νStLb_var = PSI.get_variable(container, νStLb(), D)
    γStBalLb_var = PSI.get_variable(container, γStBalLb(), D)
    γStBalUb_var = PSI.get_variable(container, γStBalUb(), D)
    jm = PSI.get_jump_model(container)
    for n in names
        con[n, 1] = JuMP.@constraint(
            jm,
            γStBalUb_var[n, 1] - γStBalLb_var[n, 1] - νStUb_var[n, 1] + νStLb_var[n, 1] == 0.0
        )
        # Written to match latex model
        for t in time_steps[2:end]
            con[n, t] = JuMP.@constraint(
                jm,
                γStBalUb_var[n, t] - γStBalLb_var[n, t] - γStBalUb_var[n, t - 1] +
                γStBalLb_var[n, t - 1] - νStUb_var[n, t] + νStLb_var[n, t] == 0.0
            )
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{OptConditionBatteryDischarge},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    # Temp Fix
    Δt_RT = 1 / 12
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    con = PSI.add_constraints_container!(container, T(), D, names, time_steps)
    λUb_var = PSI.get_variable(container, λUb(), D)
    λLb_var = PSI.get_variable(container, λLb(), D)
    μDsUb_var = PSI.get_variable(container, μDsUb(), D)
    μDsLb_var = PSI.get_variable(container, μDsLb(), D)
    γStBalLb_var = PSI.get_variable(container, γStBalLb(), D)
    γStBalUb_var = PSI.get_variable(container, γStBalUb(), D)
    κStDs_var = PSI.get_variable(container, κStDs(), D)

    jm = PSI.get_jump_model(container)
    for dev in devices
        n = PSY.get_name(dev)
        storage = PSY.get_storage(dev)
        VOM = storage.operation_cost.variable.cost
        inv_η_ds = Δt_RT / storage.efficiency.out
        # Written to match latex model
        for t in time_steps
            con[n, t] = JuMP.@constraint(
                jm,
                Δt_RT * VOM - λUb_var[n, t] + λLb_var[n, t] - μDsUb_var[n, t] +
                μDsLb_var[n, t] +
                inv_η_ds * (γStBalUb_var[n, t] - γStBalLb_var[n, t] - κStDs_var[n]) ==
                0.0
            )
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessEnergyLimitUb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    dual_var = PSI.get_variable(container, νStUb(), D)
    primal_var = PSI.get_variable(container, PSI.EnergyVariable(), D)
    k_variable = PSI.get_variable(container, ComplementarySlackVarEnergyLimitUb(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="eq")
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for dev in devices
        n = PSY.get_name(dev)
        storage = PSY.get_storage(dev)
        e_max_ds = PSY.get_state_of_charge_limits(storage).max
        for t in time_steps
            assignment_constraint[n, t] =
                JuMP.@constraint(jm, k_variable[n, t] == primal_var[n, t] - e_max_ds)
            sos_constraint[n, t] =
                JuMP.@constraint(jm, [k_variable[n, t], dual_var[n, t]] in JuMP.SOS1())
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessEnergyLimitLb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    # Lower Bound is 0.0
    # k_variable = PSI.get_variable(container, xComplementarySlacknessRenewableActivePowerLimitConstraintLb(), D)
    dual_var = PSI.get_variable(container, νStLb(), D)
    primal_var = PSI.get_variable(container, PSI.EnergyVariable(), D)
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for n in names, t in time_steps
        #assignment_constraint[n, t] =
        # JuMP.@constraint(jm, k_variable[n, t] == primal_var[n, t] - param[t] * multiplier)
        sos_constraint[n, t] =
            JuMP.@constraint(jm, [primal_var[n, t], dual_var[n, t]] in JuMP.SOS1())
    end
    return
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessEnergyAssetBalanceUb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    expression = PSI.get_expression(container, AssetPowerBalance(), D)
    variable = PSI.get_variable(container, ComplementarySlackVarEnergyAssetBalanceUb(), D)
    dual_var = PSI.get_variable(container, λUb(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="eq")
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for n in names, t in time_steps
        assignment_constraint[n, t] =
            JuMP.@constraint(jm, variable[n, t] == expression[n, t])
        sos_constraint[n, t] =
            JuMP.@constraint(jm, [variable[n, t], dual_var[n, t]] in JuMP.SOS1())
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessEnergyAssetBalanceLb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    expression = PSI.get_expression(container, AssetPowerBalance(), D)
    variable = PSI.get_variable(container, ComplementarySlackVarEnergyAssetBalanceLb(), D)
    dual_var = PSI.get_variable(container, λLb(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="eq")
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for n in names, t in time_steps
        assignment_constraint[n, t] =
            JuMP.@constraint(jm, variable[n, t] == expression[n, t])
        sos_constraint[n, t] =
            JuMP.@constraint(jm, [variable[n, t], dual_var[n, t]] in JuMP.SOS1())
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessThermalOnVariableUb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    # Temporary Map for DA to RT
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    dual_var = PSI.get_variable(container, μThUb(), D)
    primal_var = PSI.get_variable(container, ThermalPower(), D)
    varon = PSI.get_variable(container, PSI.OnVariable(), D)
    k_variable = PSI.get_variable(container, ComplementarySlackVarThermalOnVariableUb(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="eq")
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for dev in devices
        tmap = PSY.get_ext(dev)["tmap"]
        n = PSY.get_name(dev)
        thermal = PSY.get_thermal_unit(dev)
        p_max_th = PSY.get_active_power_limits(thermal).max
        for t in time_steps
            assignment_constraint[n, t] = JuMP.@constraint(
                jm,
                k_variable[n, t] == primal_var[n, t] - varon[n, tmap[t]] * p_max_th
            )
            sos_constraint[n, t] =
                JuMP.@constraint(jm, [k_variable[n, t], dual_var[n, t]] in JuMP.SOS1())
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessThermalOnVariableLb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    # temp tmap
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    dual_var = PSI.get_variable(container, μThLb(), D)
    primal_var = PSI.get_variable(container, ThermalPower(), D)
    varon = PSI.get_variable(container, PSI.OnVariable(), D)
    k_variable = PSI.get_variable(container, ComplementarySlackVarThermalOnVariableLb(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="eq")
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for dev in devices
        tmap = PSY.get_ext(dev)["tmap"]
        n = PSY.get_name(dev)
        thermal = PSY.get_thermal_unit(dev)
        p_min_th = PSY.get_active_power_limits(thermal).min
        for t in time_steps
            assignment_constraint[n, t] = JuMP.@constraint(
                jm,
                k_variable[n, t] == -primal_var[n, t] + varon[n, tmap[t]] * p_min_th
            )
            sos_constraint[n, t] =
                JuMP.@constraint(jm, [k_variable[n, t], dual_var[n, t]] in JuMP.SOS1())
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessRenewableActivePowerLimitConstraintUb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    k_variable = PSI.get_variable(
        container,
        ComplementarySlackVarRenewableActivePowerLimitConstraintUb(),
        D,
    )
    dual_var = PSI.get_variable(container, μReUb(), D)
    primal_var = PSI.get_variable(container, RenewablePower(), D)
    re_param_container = PSI.get_parameter(container, RenewablePowerTimeSeries(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="eq")
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for d in devices
        name = PSY.get_name(d)
        multiplier = PSY.get_max_active_power(d.renewable_unit)
        param = PSI.get_parameter_column_refs(re_param_container, name)
        for t in time_steps
            assignment_constraint[name, t] = JuMP.@constraint(
                jm,
                k_variable[name, t] == primal_var[name, t] - param[t] * multiplier
            )
            sos_constraint[name, t] = JuMP.@constraint(
                jm,
                [k_variable[name, t], dual_var[name, t]] in JuMP.SOS1()
            )
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessRenewableActivePowerLimitConstraintLb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    # Lower Bound is 0.0
    # k_variable = PSI.get_variable(container, xComplementarySlacknessRenewableActivePowerLimitConstraintLb(), D)
    dual_var = PSI.get_variable(container, μReLb(), D)
    primal_var = PSI.get_variable(container, RenewablePower(), D)
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for n in names, t in time_steps
        #assignment_constraint[n, t] =
        # JuMP.@constraint(jm, k_variable[n, t] == primal_var[n, t] - param[t] * multiplier)
        sos_constraint[n, t] =
            JuMP.@constraint(jm, [primal_var[n, t], dual_var[n, t]] in JuMP.SOS1())
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessBatteryStatusDischargeOnUb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    dual_var = PSI.get_variable(container, μDsLb(), D)
    primal_var = PSI.get_variable(container, BatteryDischarge(), D)
    binary = PSI.get_variable(container, BatteryStatus(), D)
    k_variable =
        PSI.get_variable(container, ComplementarySlackVarBatteryStatusDischargeOnUb(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="eq")
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for dev in devices
        n = PSY.get_name(dev)
        storage = PSY.get_storage(dev)
        p_max_ds = PSY.get_output_active_power_limits(storage).max
        for t in time_steps
            assignment_constraint[n, t] = JuMP.@constraint(
                jm,
                k_variable[n, t] == primal_var[n, t] - p_max_ds * binary[n, t]
            )
            sos_constraint[n, t] =
                JuMP.@constraint(jm, [k_variable[n, t], dual_var[n, t]] in JuMP.SOS1())
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessBatteryStatusDischargeOnLb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    # Lower Bound is 0.0
    # k_variable = PSI.get_variable(container, xComplementarySlacknessRenewableActivePowerLimitConstraintLb(), D)
    dual_var = PSI.get_variable(container, μDsLb(), D)
    primal_var = PSI.get_variable(container, BatteryDischarge(), D)
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for n in names, t in time_steps
        #assignment_constraint[n, t] =
        # JuMP.@constraint(jm, k_variable[n, t] == primal_var[n, t])
        sos_constraint[n, t] =
            JuMP.@constraint(jm, [primal_var[n, t], dual_var[n, t]] in JuMP.SOS1())
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessBatteryStatusChargeOnUb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    dual_var = PSI.get_variable(container, μDsLb(), D)
    primal_var = PSI.get_variable(container, BatteryCharge(), D)
    binary = PSI.get_variable(container, BatteryStatus(), D)
    k_variable =
        PSI.get_variable(container, ComplementarySlackVarBatteryStatusChargeOnUb(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="eq")
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for dev in devices
        n = PSY.get_name(dev)
        storage = PSY.get_storage(dev)
        p_max_ch = PSY.get_input_active_power_limits(storage).max
        for t in time_steps
            assignment_constraint[n, t] = JuMP.@constraint(
                jm,
                k_variable[n, t] == primal_var[n, t] - (1.0 - p_max_ch) * binary[n, t]
            )
            sos_constraint[n, t] =
                JuMP.@constraint(jm, [k_variable[n, t], dual_var[n, t]] in JuMP.SOS1())
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessBatteryStatusChargeOnLb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    # Lower Bound is 0.0
    # k_variable = PSI.get_variable(container, xComplementarySlacknessRenewableActivePowerLimitConstraintLb(), D)
    dual_var = PSI.get_variable(container, μChLb(), D)
    primal_var = PSI.get_variable(container, BatteryCharge(), D)
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    jm = PSI.get_jump_model(container)
    for n in names, t in time_steps
        #assignment_constraint[n, t] =
        # JuMP.@constraint(jm, k_variable[n, t] == primal_var[n, t])
        sos_constraint[n, t] =
            JuMP.@constraint(jm, [primal_var[n, t], dual_var[n, t]] in JuMP.SOS1())
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessBatteryBalanceUb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    names = [PSY.get_name(d) for d in devices]
    k_variable = PSI.get_variable(container, ComplementarySlackVarBatteryBalanceUb(), D)
    energy_var = PSI.get_variable(container, PSI.EnergyVariable(), D)
    charge_var = PSI.get_variable(container, BatteryCharge(), D)
    discharge_var = PSI.get_variable(container, BatteryDischarge(), D)
    dual_var = PSI.get_variable(container, γStBalUb(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="eq")
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), D)
    jm = PSI.get_jump_model(container)
    for ic in initial_conditions
        device = PSI.get_component(ic)
        ci_name = PSY.get_name(device)
        storage = PSY.get_storage(device)
        efficiency = PSY.get_efficiency(storage)
        assignment_constraint[ci_name, 1] = JuMP.@constraint(
            jm,
            k_variable[ci_name, 1] ==
            PSI.get_value(ic) +
            fraction_of_hour * (
                charge_var[ci_name, 1] * efficiency.in -
                (discharge_var[ci_name, 1] / efficiency.out)
            ) - energy_var[ci_name, 1]
        )
        sos_constraint[ci_name, 1] = JuMP.@constraint(
            jm,
            [k_variable[ci_name, 1], dual_var[ci_name, 1]] in JuMP.SOS1()
        )

        for t in time_steps[2:end]
            assignment_constraint[ci_name, 1] = JuMP.@constraint(
                jm,
                k_variable[ci_name, 1] ==
                energy_var[ci_name, t - 1] +
                fraction_of_hour * (
                    charge_var[ci_name, t] * efficiency.in -
                    (discharge_var[ci_name, t] / efficiency.out)
                ) - energy_var[ci_name, t]
            )
            sos_constraint[ci_name, t] = JuMP.@constraint(
                jm,
                [k_variable[ci_name, t], dual_var[ci_name, t]] in JuMP.SOS1()
            )
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{ComplementarySlacknessBatteryBalanceLb},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    resolution = PSI.get_resolution(container)
    fraction_of_hour = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    names = [PSY.get_name(d) for d in devices]
    k_variable = PSI.get_variable(container, ComplementarySlackVarBatteryBalanceLb(), D)
    energy_var = PSI.get_variable(container, PSI.EnergyVariable(), D)
    charge_var = PSI.get_variable(container, BatteryCharge(), D)
    discharge_var = PSI.get_variable(container, BatteryDischarge(), D)
    dual_var = PSI.get_variable(container, γStBalLb(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="eq")
    sos_constraint =
        PSI.add_constraints_container!(container, T(), D, names, time_steps, meta="sos")
    initial_conditions = PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), D)
    jm = PSI.get_jump_model(container)
    for ic in initial_conditions
        device = PSI.get_component(ic)
        ci_name = PSY.get_name(device)
        storage = PSY.get_storage(device)
        efficiency = PSY.get_efficiency(storage)
        assignment_constraint[ci_name, 1] = JuMP.@constraint(
            jm,
            k_variable[ci_name, 1] ==
            PSI.get_value(ic) +
            fraction_of_hour * (
                charge_var[ci_name, 1] * efficiency.in -
                (discharge_var[ci_name, 1] / efficiency.out)
            ) - energy_var[ci_name, 1]
        )
        sos_constraint[ci_name, 1] = JuMP.@constraint(
            jm,
            [k_variable[ci_name, 1], dual_var[ci_name, 1]] in JuMP.SOS1()
        )

        for t in time_steps[2:end]
            assignment_constraint[ci_name, 1] = JuMP.@constraint(
                jm,
                k_variable[ci_name, 1] ==
                energy_var[ci_name, t - 1] +
                fraction_of_hour * (
                    charge_var[ci_name, t] * efficiency.in -
                    (discharge_var[ci_name, t] / efficiency.out)
                ) - energy_var[ci_name, t]
            )
            sos_constraint[ci_name, t] = JuMP.@constraint(
                jm,
                [k_variable[ci_name, t], dual_var[ci_name, t]] in JuMP.SOS1()
            )
        end
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:ComplentarySlacknessCyclingCharge},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    k_variable = PSI.get_variable(container, ComplementarySlackVarCyclingCharge(), D)
    charge_var = PSI.get_variable(container, BatteryCharge(), D)
    dual_var = PSI.get_variable(container, κStCh(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, meta="eq")
    sos_constraint = PSI.add_constraints_container!(container, T(), D, names, meta="sos")
    jm = PSI.get_jump_model(container)
    resolution = PSI.get_resolution(container)
    Δt_RT = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    Cycles = CYCLES_PER_DAY * Δt_RT * length(time_steps) / HOURS_IN_DAY
    for dev in devices
        name = PSY.get_name(dev)
        storage = PSY.get_storage(dev)
        _, E_max = PSY.get_state_of_charge_limits(storage)
        η_ch = storage.efficiency.in * Δt_RT
        assignment_constraint[name] = JuMP.@constraint(
            jm,
            k_variable[name] ==
            sum(charge_var[name, t] * η_ch for t in time_steps) - Cycles * E_max
        )
        sos_constraint[name] =
            JuMP.@constraint(jm, [k_variable[name], dual_var[name]] in JuMP.SOS1())
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:ComplentarySlacknessCyclingDischarge},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    k_variable = PSI.get_variable(container, ComplementarySlackVarCyclingDischarge(), D)
    charge_var = PSI.get_variable(container, BatteryDischarge(), D)
    dual_var = PSI.get_variable(container, κStDs(), D)
    assignment_constraint =
        PSI.add_constraints_container!(container, T(), D, names, meta="eq")
    sos_constraint = PSI.add_constraints_container!(container, T(), D, names, meta="sos")
    jm = PSI.get_jump_model(container)
    resolution = PSI.get_resolution(container)
    Δt_RT = Dates.value(Dates.Minute(resolution)) / PSI.MINUTES_IN_HOUR
    Cycles = CYCLES_PER_DAY * Δt_RT * length(time_steps) / HOURS_IN_DAY
    for dev in devices
        name = PSY.get_name(dev)
        storage = PSY.get_storage(dev)
        _, E_max = PSY.get_state_of_charge_limits(storage)
        η_ch = storage.efficiency.in * Δt_RT
        assignment_constraint[name] = JuMP.@constraint(
            jm,
            k_variable[name] ==
            sum(charge_var[name, t] * η_ch for t in time_steps) - Cycles * E_max
        )
        sos_constraint[name] =
            JuMP.@constraint(jm, [k_variable[name], dual_var[name]] in JuMP.SOS1())
    end
    return
end

function add_constraints!(
    container::PSI.OptimizationContainer,
    T::Type{<:StrongDualityCut},
    devices::U,
    ::W,
) where {
    U <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: MerchantModelWithReserves,
} where {D <: PSY.HybridSystem}
    time_steps = PSI.get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    return
end

###################################################################
########################## Builds #################################
###################################################################

###################################################################
############# Merchant Only Energy Case Decision Model  ###########
###################################################################

function PSI.build_impl!(decision_model::PSI.DecisionModel{MerchantHybridEnergyCase})
    container = PSI.get_optimization_container(decision_model)
    sys = PSI.get_system(decision_model)
    model = container.JuMPmodel
    # Resolution
    Δt_DA = 1.0
    RT_resolution = PSY.get_time_series_resolution(sys)
    sys = PSI.get_system(decision_model)
    Δt_RT = Dates.value(Dates.Minute(RT_resolution)) / PSI.MINUTES_IN_HOUR
    # Initialize Container
    PSI.init_optimization_container!(container, PSI.CopperPlatePowerModel, sys)
    PSI.init_model_store_params!(decision_model)

    # Create Multiple Time Horizons based on ext horizons
    ext = PSY.get_ext(sys)
    dates_da = ext["λ_da_df"][!, "DateTime"]
    dates_rt = ext["λ_rt_df"][!, "DateTime"]
    len_DA = get(ext, "horizon_DA", length(dates_da))
    len_RT = get(ext, "horizon_RT", length(dates_rt))
    T_da = 1:len_DA
    T_rt = 1:len_RT
    container.time_steps = T_rt

    # Map for DA to RT
    tmap = [div(k - 1, Int(length(T_rt) / length(T_da))) + 1 for k in T_rt]

    ###############################
    ######## Parameters ###########
    ###############################

    hybrids = collect(PSY.get_components(PSY.HybridSystem, sys))
    h_names = PSY.get_name.(hybrids)
    for h in hybrids
        PSY.get_ext(h)["T_da"] = T_da
        PSY.get_ext(h)["tmap"] = tmap
    end

    services = Set()
    for d in hybrids
        union!(services, PSY.get_services(d))
    end

    ###############################
    ######## Variables ############
    ###############################

    # Add Market variables
    for v in [EnergyDABidOut, EnergyDABidIn]
        PSI.add_variables!(container, v, hybrids, MerchantModelEnergyOnly())
    end

    for v in [EnergyRTBidOut, EnergyRTBidIn]
        PSI.add_variables!(container, v, hybrids, MerchantModelEnergyOnly())
    end

    # Add PCC Variables
    for v in
        [PSI.ActivePowerOutVariable, PSI.ActivePowerInVariable, PSI.ReservationVariable]
        PSI.add_variables!(container, v, hybrids, MerchantModelEnergyOnly())
    end

    # Add internal Asset Variables

    ###############################
    ####### Parameters ############
    ###############################

    _hybrids_with_loads = [d for d in hybrids if PSY.get_electric_load(d) !== nothing]
    _hybrids_with_renewable = [d for d in hybrids if PSY.get_renewable_unit(d) !== nothing]
    _hybrids_with_storage = [d for d in hybrids if PSY.get_storage(d) !== nothing]
    _hybrids_with_thermal = [d for d in hybrids if PSY.get_thermal_unit(d) !== nothing]

    if !isempty(_hybrids_with_renewable)
        PSI.add_variables!(
            container,
            RenewablePower,
            _hybrids_with_renewable,
            MerchantModelEnergyOnly(),
        )
        if get(decision_model.ext, "RT", false)
            add_time_series_parameters!(
                container,
                RenewablePowerTimeSeries(),
                _hybrids_with_renewable,
                "RenewableDispatch__max_active_power",
            )
        else
            add_time_series_parameters!(
                container,
                RenewablePowerTimeSeries(),
                _hybrids_with_renewable,
                "RenewableDispatch__max_active_power_da",
            )
        end
    end

    if !isempty(_hybrids_with_loads)
        add_time_series_parameters!(
            container,
            ElectricLoadTimeSeries(),
            _hybrids_with_loads,
        )
        P_ld_container =
            PSI.get_parameter(container, ElectricLoadTimeSeries(), PSY.HybridSystem)
        P_ld_multiplier = PSI.get_parameter_multiplier_array(
            container,
            ElectricLoadTimeSeries(),
            PSY.HybridSystem,
        )
    end

    if !isempty(_hybrids_with_storage)
        for v in [BatteryCharge, BatteryDischarge, PSI.EnergyVariable, BatteryStatus]
            PSI.add_variables!(container, v, hybrids, MerchantModelEnergyOnly())
        end
        PSI.add_initial_condition!(
            container,
            _hybrids_with_storage,
            MerchantModelEnergyOnly(),
            PSI.InitialEnergyLevel(),
        )
    end

    if !isempty(_hybrids_with_thermal)
        for v in [ThermalPower, PSI.OnVariable]
            PSI.add_variables!(container, v, hybrids, MerchantModelEnergyOnly())
        end
    end

    ###############################
    ####### Obj. Function #########
    ###############################

    # This function add the parameters for both variables DABidOut and DABidIn
    PSI.add_parameters!(
        container,
        DayAheadEnergyPrice(),
        hybrids,
        MerchantModelEnergyOnly(),
    )

    λ_da_pos = PSI.get_parameter_array(
        container,
        DayAheadEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidOut",
    )

    λ_da_neg = PSI.get_parameter_array(
        container,
        DayAheadEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidIn",
    )

    # This function add the parameters for both variables RTBidOut and RTBidIn
    PSI.add_parameters!(
        container,
        RealTimeEnergyPrice(),
        hybrids,
        MerchantModelEnergyOnly(),
    )

    λ_rt_pos = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyRTBidOut",
    )

    λ_rt_neg = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyRTBidIn",
    )

    λ_dart_pos = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidOut",
    )

    λ_dart_neg = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidIn",
    )

    # DA costs
    eb_da_out = PSI.get_variable(container, EnergyDABidOut(), PSY.HybridSystem)
    eb_da_in = PSI.get_variable(container, EnergyDABidIn(), PSY.HybridSystem)
    if !isempty(_hybrids_with_thermal)
        on_th = PSI.get_variable(container, PSI.OnVariable(), PSY.HybridSystem)
    end

    for t in T_da, dev in hybrids
        name = PSY.get_name(dev)
        lin_cost_da_out = 100.0*Δt_DA * λ_da_pos[name, t] * eb_da_out[name, t]
        lin_cost_da_in = -100.0*Δt_DA * λ_da_neg[name, t] * eb_da_in[name, t]
        PSI.add_to_objective_variant_expression!(container, lin_cost_da_out)
        PSI.add_to_objective_variant_expression!(container, lin_cost_da_in)
        if !isnothing(dev.thermal_unit)
            t_gen = dev.thermal_unit
            three_cost = PSY.get_operation_cost(t_gen)
            C_th_fix = three_cost.fixed # $/h
            lin_cost_on_th = -Δt_DA * C_th_fix * on_th[name, t]
            PSI.add_to_objective_invariant_expression!(container, lin_cost_on_th)
        end
    end

    # RT costs
    eb_rt_out = PSI.get_variable(container, EnergyRTBidOut(), PSY.HybridSystem)
    eb_rt_in = PSI.get_variable(container, EnergyRTBidIn(), PSY.HybridSystem)
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), PSY.HybridSystem)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), PSY.HybridSystem)
    status = PSI.get_variable(container, PSI.ReservationVariable(), PSY.HybridSystem)
    if !isempty(_hybrids_with_thermal)
        p_th = PSI.get_variable(container, ThermalPower(), PSY.HybridSystem)
    end
    if !isempty(_hybrids_with_renewable)
        p_re = PSI.get_variable(container, RenewablePower(), PSY.HybridSystem)
    end
    if !isempty(_hybrids_with_storage)
        p_ch = PSI.get_variable(container, BatteryCharge(), PSY.HybridSystem)
        p_ds = PSI.get_variable(container, BatteryDischarge(), PSY.HybridSystem)
        e_st = PSI.get_variable(container, PSI.EnergyVariable(), PSY.HybridSystem)
        status_st = PSI.get_variable(container, BatteryStatus(), PSY.HybridSystem)
    end

    for dev in hybrids
        name = PSY.get_name(dev)
        for t in T_rt
            lin_cost_rt_out = 100.0*Δt_RT * λ_rt_pos[name, t] * eb_rt_out[name, t]
            lin_cost_rt_in = -100.0*Δt_RT * λ_rt_neg[name, t] * eb_rt_in[name, t]
            lin_cost_dart_out = -100.0*Δt_RT * λ_dart_neg[name, t] * eb_da_out[name, tmap[t]]
            lin_cost_dart_in = 100.0*Δt_RT * λ_dart_pos[name, t] * eb_da_in[name, tmap[t]]
            PSI.add_to_objective_variant_expression!(container, lin_cost_rt_out)
            PSI.add_to_objective_variant_expression!(container, lin_cost_rt_in)
            PSI.add_to_objective_variant_expression!(container, lin_cost_dart_out)
            PSI.add_to_objective_variant_expression!(container, lin_cost_dart_in)
            if !isnothing(dev.thermal_unit)
                t_gen = dev.thermal_unit
                three_cost = PSY.get_operation_cost(t_gen)
                first_part = three_cost.variable[1]
                second_part = three_cost.variable[2]
                slope = (second_part[1] - first_part[1]) / (second_part[2] - first_part[2]) # $/MWh
                C_th_var = slope * 100.0 # Multiply by 100 to transform to $/pu
                lin_cost_p_th = -Δt_RT * C_th_var * p_th[name, t]
                PSI.add_to_objective_invariant_expression!(container, lin_cost_p_th)
            end
            if !isnothing(dev.storage)
                VOM = dev.storage.operation_cost.variable.cost
                lin_cost_p_ch = -Δt_RT * VOM * p_ch[name, t]
                lin_cost_p_ds = -Δt_RT * VOM * p_ds[name, t]
                PSI.add_to_objective_invariant_expression!(container, lin_cost_p_ch)
                PSI.add_to_objective_invariant_expression!(container, lin_cost_p_ds)
            end
        end
    end
    JuMP.@objective(
        model,
        MOI.MAX_SENSE,
        PSI.get_objective_function(container.objective_function)
    )

    ###############################
    ######## Constraints ##########
    ###############################

    # BidBalance
    constraint_eb_out = PSI.add_constraints_container!(
        container,
        BidBalanceOut(),
        PSY.HybridSystem,
        h_names,
        T_rt,
    )
    constraint_eb_in = PSI.add_constraints_container!(
        container,
        BidBalanceIn(),
        PSY.HybridSystem,
        h_names,
        T_rt,
    )

    constraint_status_bid_in = PSI.add_constraints_container!(
        container,
        StatusInOn(),
        PSY.HybridSystem,
        h_names,
        T_rt,
    )

    constraint_status_bid_out = PSI.add_constraints_container!(
        container,
        StatusOutOn(),
        PSY.HybridSystem,
        h_names,
        T_rt,
    )

    constraint_balance = PSI.add_constraints_container!(
        container,
        EnergyAssetBalance(),
        PSY.HybridSystem,
        h_names,
        T_rt,
    )

    # Thermal
    if !isempty(_hybrids_with_thermal)
        constraint_thermal_on = PSI.add_constraints_container!(
            container,
            ThermalOnVariableUb(),
            PSY.HybridSystem,
            h_names,
            T_rt,
        )

        constraint_thermal_off = PSI.add_constraints_container!(
            container,
            ThermalOnVariableLb(),
            PSY.HybridSystem,
            h_names,
            T_rt,
        )
    end
    # Battery Charging
    if !isempty(_hybrids_with_storage)
        constraint_battery_charging = PSI.add_constraints_container!(
            container,
            BatteryStatusChargeOn(),
            PSY.HybridSystem,
            h_names,
            T_rt,
        )

        constraint_battery_discharging = PSI.add_constraints_container!(
            container,
            BatteryStatusDischargeOn(),
            PSY.HybridSystem,
            h_names,
            T_rt,
        )

        constraint_battery_balance = PSI.add_constraints_container!(
            container,
            BatteryBalance(),
            PSY.HybridSystem,
            h_names,
            T_rt,
        )

        constraint_cycling_charge = PSI.add_constraints_container!(
            container,
            CyclingCharge(),
            PSY.HybridSystem,
            h_names,
        )

        constraint_cycling_discharge = PSI.add_constraints_container!(
            container,
            CyclingDischarge(),
            PSY.HybridSystem,
            h_names,
        )
    end

    if !isempty(_hybrids_with_renewable)
        renewable_upper_bound = PSI.add_constraints_container!(
            container,
            RenewableActivePowerLimitConstraint(),
            PSY.HybridSystem,
            h_names,
            T_rt,
            meta="ub",
        )

        re_param_container =
            PSI.get_parameter(container, RenewablePowerTimeSeries(), PSY.HybridSystem)
    end
    for t in T_rt
        for dev in hybrids
            name = PSY.get_name(dev)
            P_max_pcc = PSY.get_output_active_power_limits(dev).max
            # Market Constraint Bids in/out
            constraint_eb_out[name, t] =
                JuMP.@constraint(model, eb_rt_out[name, t] == p_out[name, t])
            constraint_eb_in[name, t] =
                JuMP.@constraint(model, eb_rt_in[name, t] == p_in[name, t])
            # Status Bids
            constraint_status_bid_in[name, t] = JuMP.@constraint(
                model,
                (1.0 - status[name, t]) * P_max_pcc .>= p_in[name, t]
            )
            constraint_status_bid_out[name, t] =
                JuMP.@constraint(model, status[name, t] * P_max_pcc .>= p_out[name, t])
            # Power Balance
            if !isnothing(dev.electric_load)
                P_ld_array = PSI.get_parameter_column_refs(P_ld_container, name)
            else
                P_ld_array = zeros(length(p_out[name, :]))
            end
            constraint_balance[name, t] = JuMP.@constraint(
                model,
                p_th[name, t] + p_re[name, t] + p_ds[name, t] - p_ch[name, t] -
                P_ld_array[t] - p_out[name, t] + # TODO: Restore P_ld_multiplier
                p_in[name, t] == 0.0
            )
        end
        # Thermal Status
        for dev in _hybrids_with_thermal
            name = PSY.get_name(dev)
            t_gen = dev.thermal_unit
            P_min_th, P_max_th = PSY.get_active_power_limits(t_gen)
            constraint_thermal_on[name, t] =
                JuMP.@constraint(model, p_th[name, t] <= on_th[name, tmap[t]] * P_max_th)
            constraint_thermal_off[name, t] =
                JuMP.@constraint(model, p_th[name, t] >= on_th[name, tmap[t]] * P_min_th)
        end
        for dev in _hybrids_with_renewable
            name = PSY.get_name(dev)
            multiplier = PSY.get_max_active_power(dev.renewable_unit)
            param = PSI.get_parameter_column_refs(re_param_container, name)
            renewable_upper_bound[name, t] = JuMP.@constraint(
                PSI.get_jump_model(container),
                p_re[name, t] <= multiplier * param[t]
            )
        end
    end
    # Storage Conditions
    if !isempty(_hybrids_with_storage)
        initial_conditions =
            PSI.get_initial_condition(container, PSI.InitialEnergyLevel(), PSY.HybridSystem)
        for ic in initial_conditions
            device = PSI.get_component(ic)
            name = PSY.get_name(device)
            storage = PSY.get_storage(device)
            P_ch_max = PSY.get_input_active_power_limits(storage).max
            P_ds_max = PSY.get_output_active_power_limits(storage).max
            η_ch = storage.efficiency.in
            η_ds = storage.efficiency.out
            inv_η_ds = 1.0 / η_ds
            for t in T_rt
                # Battery Constraints
                constraint_battery_charging[name, t] = JuMP.@constraint(
                    model,
                    p_ch[name, t] <= (1.0 - status_st[name, t]) * P_ch_max
                )
                constraint_battery_discharging[name, t] =
                    JuMP.@constraint(model, p_ds[name, t] <= status_st[name, t] * P_ds_max)
                # State of Charge
                if t == 1
                    constraint_battery_balance[name, t] = JuMP.@constraint(
                        model,
                        PSI.get_value(ic) +
                        Δt_RT * (p_ch[name, t] * η_ch - p_ds[name, t] * inv_η_ds) ==
                        e_st[name, t]
                    )
                else
                    constraint_battery_balance[name, t] = JuMP.@constraint(
                        model,
                        e_st[name, t - 1] +
                        Δt_RT * (p_ch[name, t] * η_ch - p_ds[name, t] * inv_η_ds) ==
                        e_st[name, t]
                    )
                end
            end
        end

        # Cycling Constraints
        # Same Cycles for each Storage

        Cycles = CYCLES_PER_DAY * Δt_RT * length(T_rt) / HOURS_IN_DAY
        for dev in _hybrids_with_storage
            name = PSY.get_name(dev)
            storage = dev.storage
            η_ch = storage.efficiency.in
            η_ds = storage.efficiency.out
            inv_η_ds = 1.0 / η_ds
            E_min, E_max = PSY.get_state_of_charge_limits(storage)
            constraint_cycling_charge[name] = JuMP.@constraint(
                model,
                inv_η_ds * Δt_RT * sum(p_ds[name, t] for t in T_rt) <= Cycles * E_max
            )
            constraint_cycling_discharge[name] = JuMP.@constraint(
                model,
                η_ch * Δt_RT * sum(p_ch[name, t] for t in T_rt) <= Cycles * E_max
            )
        end
    end
    device_model = PSI.get_model(PSI.get_template(decision_model), PSY.HybridSystem)
    PSI.add_feedforward_arguments!(container, device_model, hybrids)
    PSI.serialize_metadata!(container, PSI.get_output_dir(decision_model))
    return
end

###################################################################
########## Merchant Energy + Reserves Case Decision Model  ########
###################################################################
function PSI.build_impl!(decision_model::PSI.DecisionModel{MerchantHybridCooptimizerCase})
    container = PSI.get_optimization_container(decision_model)
    model = container.JuMPmodel
    sys = PSI.get_system(decision_model)
    T = PSY.HybridSystem
    # Resolution
    RT_resolution = PSY.get_time_series_resolution(sys)
    Δt_DA = 1.0
    Δt_RT = Dates.value(Dates.Minute(RT_resolution)) / PSI.MINUTES_IN_HOUR
    # Initialize Container
    PSI.init_optimization_container!(container, PSI.CopperPlatePowerModel, sys)
    PSI.init_model_store_params!(decision_model)

    # Create Multiple Time Horizons based on ext horizons
    ext = PSY.get_ext(sys)
    dates_da = ext["λ_da_df"][!, "DateTime"]
    dates_rt = ext["λ_rt_df"][!, "DateTime"]
    len_DA = get(ext, "horizon_DA", length(dates_da))
    len_RT = get(ext, "horizon_RT", length(dates_rt))
    T_da = 1:len_DA
    T_rt = 1:len_RT
    container.time_steps = T_rt
    time_steps = T_rt

    # Map for DA to RT
    tmap = [div(k - 1, Int(length(T_rt) / length(T_da))) + 1 for k in T_rt]

    ###############################
    ######## Parameters ###########
    ###############################

    hybrids = collect(PSY.get_components(PSY.HybridSystem, sys))
    h_names = PSY.get_name.(hybrids)
    for h in hybrids
        PSY.get_ext(h)["T_da"] = T_da
        PSY.get_ext(h)["tmap"] = tmap
    end

    services = Set()
    for h in hybrids
        union!(services, PSY.get_services(h))
    end

    ###############################
    ######## Variables ############
    ###############################

    # Add Market variables
    for v in [EnergyDABidOut, EnergyDABidIn]
        PSI.add_variables!(container, v, hybrids, MerchantModelWithReserves())
    end

    for v in [EnergyRTBidOut, EnergyRTBidIn]
        PSI.add_variables!(container, v, hybrids, MerchantModelWithReserves())
    end

    # Add PCC Variables
    for v in
        [PSI.ActivePowerOutVariable, PSI.ActivePowerInVariable, PSI.ReservationVariable]
        PSI.add_variables!(container, v, hybrids, MerchantModelWithReserves())
    end

    # Add Reserve Variables
    for v in [BidReserveVariableOut, BidReserveVariableIn]
        PSI.add_variables!(container, v, hybrids, MerchantModelWithReserves())
    end

    # Add Reserve Up/Down Out/In Expression
    PSI.lazy_container_addition!(
        container,
        TotalReserveOutUpExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        TotalReserveOutDownExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        TotalReserveInUpExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        TotalReserveInDownExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    # Out Total Up
    add_to_expression!(
        container,
        TotalReserveOutUpExpression,
        BidReserveVariableOut,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # Out Total Down
    add_to_expression!(
        container,
        TotalReserveOutDownExpression,
        BidReserveVariableOut,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # In Total Up
    add_to_expression!(
        container,
        TotalReserveInUpExpression,
        BidReserveVariableIn,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # In Total Down
    add_to_expression!(
        container,
        TotalReserveInDownExpression,
        BidReserveVariableIn,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # Add Served Reserve Up/Down Out/In Expression
    PSI.lazy_container_addition!(
        container,
        ServedReserveOutUpExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        ServedReserveOutDownExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        ServedReserveInUpExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        ServedReserveInDownExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    # Out Total Up
    add_to_expression!(
        container,
        ServedReserveOutUpExpression,
        BidReserveVariableOut,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # Out Total Down
    add_to_expression!(
        container,
        ServedReserveOutDownExpression,
        BidReserveVariableOut,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # In Total Up
    add_to_expression!(
        container,
        ServedReserveInUpExpression,
        BidReserveVariableIn,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # In Total Down
    add_to_expression!(
        container,
        ServedReserveInDownExpression,
        BidReserveVariableIn,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    ###############################
    ####### Parameters ############
    ###############################

    _hybrids_with_loads = [d for d in hybrids if PSY.get_electric_load(d) !== nothing]
    _hybrids_with_renewable = [d for d in hybrids if PSY.get_renewable_unit(d) !== nothing]
    _hybrids_with_storage = [d for d in hybrids if PSY.get_storage(d) !== nothing]
    _hybrids_with_thermal = [d for d in hybrids if PSY.get_thermal_unit(d) !== nothing]

    ## Renewable Variables and Expressions ##
    if !isempty(_hybrids_with_renewable)
        PSI.add_variables!(
            container,
            RenewablePower,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
        )
        PSI.add_variables!(
            container,
            EnergyRenewableBid,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
        )
        add_time_series_parameters!(
            container,
            RenewablePowerTimeSeries(),
            _hybrids_with_renewable,
            "RenewableDispatch__max_active_power_da",
        )
        PSI.add_variables!(
            container,
            RenewableReserveVariable,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
        )

        # Create renewable total up reserves
        PSI.lazy_container_addition!(
            container,
            RenewableReserveUpExpression(),
            T,
            PSY.get_name.(_hybrids_with_renewable),
            time_steps,
        )

        # Create renewable total down reserves
        PSI.lazy_container_addition!(
            container,
            RenewableReserveDownExpression(),
            T,
            PSY.get_name.(_hybrids_with_renewable),
            time_steps,
        )

        add_to_expression_componentreserveup!(
            container,
            RenewableReserveUpExpression,
            RenewableReserveVariable,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
            time_steps,
        )

        add_to_expression_componentreservedown!(
            container,
            RenewableReserveDownExpression,
            RenewableReserveVariable,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
            time_steps,
        )
    end

    ## Load Variables and Expressions ##
    if !isempty(_hybrids_with_loads)
        add_time_series_parameters!(
            container,
            ElectricLoadTimeSeries(),
            _hybrids_with_loads,
        )
        P_ld_container =
            PSI.get_parameter(container, ElectricLoadTimeSeries(), PSY.HybridSystem)
        P_ld_multiplier = PSI.get_parameter_multiplier_array(
            container,
            ElectricLoadTimeSeries(),
            PSY.HybridSystem,
        )
    end

    ## Storage Variables and Expressions ##
    if !isempty(_hybrids_with_storage)
        for v in [
            BatteryCharge,
            BatteryDischarge,
            PSI.EnergyVariable,
            BatteryStatus,
            ChargingReserveVariable,
            DischargingReserveVariable,
            EnergyBatteryChargeBid,
            EnergyBatteryDischargeBid,
        ]
            PSI.add_variables!(
                container,
                v,
                _hybrids_with_storage,
                MerchantModelWithReserves(),
            )
        end
        PSI.add_initial_condition!(
            container,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
            PSI.InitialEnergyLevel(),
        )

        # Add reserve expressions for charging unit
        PSI.lazy_container_addition!(
            container,
            ChargeReserveUpExpression(),
            T,
            PSY.get_name.(_hybrids_with_storage),
            time_steps,
        )

        PSI.lazy_container_addition!(
            container,
            ChargeReserveDownExpression(),
            T,
            PSY.get_name.(_hybrids_with_storage),
            time_steps,
        )

        add_to_expression_componentreserveup!(
            container,
            ChargeReserveUpExpression,
            ChargingReserveVariable,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
            time_steps,
        )

        add_to_expression_componentreservedown!(
            container,
            ChargeReserveDownExpression,
            ChargingReserveVariable,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
            time_steps,
        )

        # Add reserve expressions for discharging unit
        PSI.lazy_container_addition!(
            container,
            DischargeReserveUpExpression(),
            T,
            PSY.get_name.(_hybrids_with_storage),
            time_steps,
        )

        PSI.lazy_container_addition!(
            container,
            DischargeReserveDownExpression(),
            T,
            PSY.get_name.(_hybrids_with_storage),
            time_steps,
        )

        add_to_expression_componentreserveup!(
            container,
            DischargeReserveUpExpression,
            DischargingReserveVariable,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
            time_steps,
        )

        add_to_expression_componentreservedown!(
            container,
            DischargeReserveDownExpression,
            DischargingReserveVariable,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
            time_steps,
        )
    end

    if !isempty(_hybrids_with_thermal)
        for v in [ThermalPower, PSI.OnVariable, ThermalReserveVariable, EnergyThermalBid]
            PSI.add_variables!(
                container,
                v,
                _hybrids_with_thermal,
                MerchantModelWithReserves(),
            )
        end
        # Add Expressions for Thermal
        PSI.lazy_container_addition!(
            container,
            ThermalReserveUpExpression(),
            T,
            PSY.get_name.(_hybrids_with_thermal),
            time_steps,
        )

        PSI.lazy_container_addition!(
            container,
            ThermalReserveDownExpression(),
            T,
            PSY.get_name.(_hybrids_with_thermal),
            time_steps,
        )

        add_to_expression_componentreserveup!(
            container,
            ThermalReserveUpExpression,
            ThermalReserveVariable,
            _hybrids_with_thermal,
            MerchantModelWithReserves(),
            time_steps,
        )
        add_to_expression_componentreservedown!(
            container,
            ThermalReserveDownExpression,
            ThermalReserveVariable,
            _hybrids_with_thermal,
            MerchantModelWithReserves(),
            time_steps,
        )
    end

    ###############################
    ####### Obj. Function #########
    ###############################

    # This function add the parameters for both variables DABidOut and DABidIn
    PSI.add_parameters!(
        container,
        DayAheadEnergyPrice(),
        hybrids,
        MerchantModelWithReserves(),
    )

    λ_da_pos = PSI.get_parameter_array(
        container,
        DayAheadEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidOut",
    )

    λ_da_neg = PSI.get_parameter_array(
        container,
        DayAheadEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidIn",
    )

    # This function add the parameters for both variables RTBidOut and RTBidIn
    PSI.add_parameters!(
        container,
        RealTimeEnergyPrice(),
        hybrids,
        MerchantModelWithReserves(),
    )

    λ_rt_pos = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyRTBidOut",
    )

    λ_rt_neg = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyRTBidIn",
    )

    λ_dart_pos = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidOut",
    )

    λ_dart_neg = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidIn",
    )

    # This function add the parameters for each Ancillary Service Variable (Out and In)
    PSI.add_parameters!(
        container,
        AncillaryServicePrice(),
        hybrids,
        MerchantModelWithReserves(),
    )

    # DA costs
    eb_da_out = PSI.get_variable(container, EnergyDABidOut(), PSY.HybridSystem)
    eb_da_in = PSI.get_variable(container, EnergyDABidIn(), PSY.HybridSystem)
    if !isempty(_hybrids_with_thermal)
        on_th = PSI.get_variable(container, PSI.OnVariable(), PSY.HybridSystem)
    end

    for t in T_da, dev in hybrids
        name = PSY.get_name(dev)
        lin_cost_da_out = Δt_DA * λ_da_pos[name, t] * eb_da_out[name, t]
        lin_cost_da_in = -Δt_DA * λ_da_neg[name, t] * eb_da_in[name, t]
        PSI.add_to_objective_variant_expression!(container, lin_cost_da_out)
        PSI.add_to_objective_variant_expression!(container, lin_cost_da_in)
        dev_services = PSY.get_services(dev)
        for service in dev_services
            service_name = PSY.get_name(service)
            price_service_out = PSI.get_parameter_array(
                container,
                AncillaryServicePrice(),
                PSY.HybridSystem,
                "BidReserveVariableOut_$(service_name)",
            )
            sb_service_out = PSI.get_variable(
                container,
                BidReserveVariableOut(),
                typeof(service),
                service_name,
            )
            price_service_in = PSI.get_parameter_array(
                container,
                AncillaryServicePrice(),
                PSY.HybridSystem,
                "BidReserveVariableIn_$(service_name)",
            )
            sb_service_in = PSI.get_variable(
                container,
                BidReserveVariableIn(),
                typeof(service),
                service_name,
            )
            service_out_cost = Δt_DA * price_service_out[name, t] * sb_service_out[name, t]
            service_in_cost = Δt_DA * price_service_in[name, t] * sb_service_in[name, t]
            PSI.add_to_objective_variant_expression!(container, service_out_cost)
            PSI.add_to_objective_variant_expression!(container, service_in_cost)
        end
        if !isnothing(dev.thermal_unit)
            # Workaround
            t_gen = dev.thermal_unit
            three_cost = PSY.get_operation_cost(t_gen)
            C_th_fix = three_cost.fixed # $/h
            lin_cost_on_th = -Δt_DA * C_th_fix * on_th[name, t]
            PSI.add_to_objective_invariant_expression!(container, lin_cost_on_th)
        end
    end

    # RT costs
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), PSY.HybridSystem)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), PSY.HybridSystem)

    # Thermal Variable Cost
    if !isempty(_hybrids_with_thermal)
        p_th = PSI.get_variable(container, ThermalPower(), PSY.HybridSystem)
    end
    # TODO: Decide if we include cost of curtailment or not
    # PSI.add_variable_cost!(container, RenewablePower(), _hybrids_with_renewable, MerchantModelWithReserves())
    # Battery Cost
    PSI.add_proportional_cost!(
        container,
        BatteryCharge(),
        _hybrids_with_storage,
        MerchantModelWithReserves(),
    )
    PSI.add_proportional_cost!(
        container,
        BatteryDischarge(),
        _hybrids_with_storage,
        MerchantModelWithReserves(),
    )

    # Storage Variable Cost
    if !isempty(_hybrids_with_storage)
        p_ch = PSI.get_variable(container, BatteryCharge(), PSY.HybridSystem)
        p_ds = PSI.get_variable(container, BatteryDischarge(), PSY.HybridSystem)
    end

    # RT bids and DART arbitrage
    for t in T_rt, dev in hybrids
        name = PSY.get_name(dev)
        lin_cost_rt_out = Δt_RT * λ_rt_pos[name, t] * p_out[name, t]
        lin_cost_rt_in = -Δt_RT * λ_rt_neg[name, t] * p_in[name, t]
        lin_cost_dart_out = -Δt_RT * λ_dart_neg[name, t] * eb_da_out[name, tmap[t]]
        lin_cost_dart_in = Δt_RT * λ_dart_pos[name, t] * eb_da_in[name, tmap[t]]
        PSI.add_to_objective_variant_expression!(container, lin_cost_rt_out)
        PSI.add_to_objective_variant_expression!(container, lin_cost_rt_in)
        PSI.add_to_objective_variant_expression!(container, lin_cost_dart_out)
        PSI.add_to_objective_variant_expression!(container, lin_cost_dart_in)
        if !isnothing(dev.thermal_unit)
            # Workaround to add ThermalCost with a Linear Cost Since the model doesn't include PWL cost
            t_gen = dev.thermal_unit
            three_cost = PSY.get_operation_cost(t_gen)
            first_part = three_cost.variable[1]
            second_part = three_cost.variable[2]
            slope = (second_part[1] - first_part[1]) / (second_part[2] - first_part[2]) # $/MWh
            fix_cost = three_cost.fixed # $/h
            C_th_var = slope * 100.0 # Multiply by 100 to transform to $/pu
            lin_cost_p_th = -Δt_RT * C_th_var * p_th[name, t]
            PSI.add_to_objective_invariant_expression!(container, lin_cost_p_th)
        end
        if !isnothing(dev.storage)
            VOM = dev.storage.operation_cost.variable.cost
            lin_cost_p_ch = -Δt_RT * VOM * p_ch[name, t]
            lin_cost_p_ds = -Δt_RT * VOM * p_ds[name, t]
            PSI.add_to_objective_invariant_expression!(container, lin_cost_p_ch)
            PSI.add_to_objective_invariant_expression!(container, lin_cost_p_ds)
        end
    end
    JuMP.@objective(
        model,
        MOI.MAX_SENSE,
        PSI.get_objective_function(container.objective_function)
    )

    ###############################
    ######## Constraints ##########
    ###############################

    # BidBalance
    constraint_eb_out = PSI.add_constraints_container!(
        container,
        BidBalanceOut(),
        PSY.HybridSystem,
        h_names,
        T_rt,
    )
    constraint_eb_in = PSI.add_constraints_container!(
        container,
        BidBalanceIn(),
        PSY.HybridSystem,
        h_names,
        T_rt,
    )

    # PCC Limits for Day-Ahead Bid Out
    add_constraints_dayaheadlimit_out_withreserves!(
        container,
        DayAheadBidOutRangeLimit,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # PCC Limits for Day-Ahead Bid In
    add_constraints_dayaheadlimit_in_withreserves!(
        container,
        DayAheadBidInRangeLimit,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # PCC Limits for Real-Time Bid Out
    add_constraints_realtimelimit_out_withreserves!(
        container,
        RealTimeBidOutRangeLimit,
        hybrids,
        MerchantModelWithReserves(),
        time_steps,
    )

    add_constraints_realtimelimit_in_withreserves!(
        container,
        RealTimeBidInRangeLimit,
        hybrids,
        MerchantModelWithReserves(),
        time_steps,
    )

    # Thermal
    if !isempty(_hybrids_with_thermal)
        # Thermal Limits with Reserves
        _add_thermallimit_withreserves!(
            container,
            ThermalReserveLimit,
            _hybrids_with_thermal,
            MerchantModelWithReserves(),
        )

        # Thermal Limit On without Reserves
        _add_constraints_thermalon_variableon!(
            container,
            ThermalOnVariableUb,
            _hybrids_with_thermal,
            MerchantModelWithReserves(),
        )

        # Thermal Limit Off without Reserves
        _add_constraints_thermalon_variableoff!(
            container,
            ThermalOnVariableLb,
            _hybrids_with_thermal,
            MerchantModelWithReserves(),
        )
    end
    # Battery Charging
    if !isempty(_hybrids_with_storage)
        # Discharging Limits with Reserves
        _add_constraints_discharging_reservelimit!(
            container,
            DischargingReservePowerLimit,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
        )

        # Discharging Limits without Reserves
        _add_constraints_batterydischargeon!(
            container,
            BatteryStatusDischargeOn,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
        )

        # Charging Limits with Reserves
        _add_constraints_charging_reservelimit!(
            container,
            ChargingReservePowerLimit,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
        )

        # Charging Limits without Reserve
        _add_constraints_batterychargeon!(
            container,
            BatteryStatusChargeOn,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
        )

        # Battery Balance
        _add_constraints_batterybalance!(
            container,
            BatteryBalance,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
        )

        # TODO: set-up cycling in the decision model
        cycling = true
        if cycling
            _add_constraints_cyclingcharge!(
                container,
                CyclingCharge,
                _hybrids_with_storage,
                MerchantModelWithReserves(),
            )
            _add_constraints_cyclingdischarge!(
                container,
                CyclingDischarge,
                _hybrids_with_storage,
                MerchantModelWithReserves(),
            )
        end

        # Reserve Coverage
        for service in services
            _add_constraints_reservecoverage_withreserves!(
                container,
                ReserveCoverageConstraint,
                _hybrids_with_storage,
                service,
                MerchantModelWithReserves(),
            )
            _add_constraints_reservecoverage_withreserves_endofperiod!(
                container,
                ReserveCoverageConstraintEndOfPeriod,
                _hybrids_with_storage,
                service,
                MerchantModelWithReserves(),
            )
        end
    end

    if !isempty(_hybrids_with_renewable)
        # Add Renewable Limit without Reserves
        _add_constraints_renewablelimit!(
            container,
            RenewableActivePowerLimitConstraint,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
        )
        # Add Renewable Limit with Reserves
        _add_constraints_renewablereserve_limit!(
            container,
            RenewableReserveLimit,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
        )
    end

    # Asset Balance
    _add_constraints_energyassetbalance!(
        container,
        EnergyAssetBalance,
        hybrids,
        MerchantModelWithReserves(),
    )

    # Energy Bid Balance
    _add_constraints_energybidassetbalance!(
        container,
        EnergyBidAssetBalance,
        hybrids,
        MerchantModelWithReserves(),
    )

    # Reserve Bid Balance
    for service in services
        _add_constraints_reservebalance!(
            container,
            ReserveBalance,
            hybrids,
            service,
            MerchantModelWithReserves(),
            time_steps,
        )
    end

    # Status PCC Operation Out ON
    _add_constraints_statusout!(
        container,
        StatusOutOn,
        hybrids,
        MerchantModelWithReserves(),
    )

    # Status PCC Operation Out In
    _add_constraints_statusin!(container, StatusInOn, hybrids, MerchantModelWithReserves())

    # Market Convergence to Assets

    _add_constraints_out_marketconvergence!(
        container,
        MarketOutConvergence,
        hybrids,
        MerchantModelWithReserves(),
    )

    _add_constraints_in_marketconvergence!(
        container,
        MarketInConvergence,
        hybrids,
        MerchantModelWithReserves(),
    )

    PSI.serialize_metadata!(container, PSI.get_output_dir(decision_model))
    return
end

###################################################################
### Bi-level - Merchant Energy + Reserves Case Decision Model  ####
###################################################################
function PSI.build_impl!(decision_model::PSI.DecisionModel{MerchantHybridBilevelCase})
    container = PSI.get_optimization_container(decision_model)
    model = container.JuMPmodel
    sys = PSI.get_system(decision_model)
    T = PSY.HybridSystem
    # Resolution
    RT_resolution = PSY.get_time_series_resolution(sys)
    Δt_DA = 1.0
    Δt_RT = Dates.value(Dates.Minute(RT_resolution)) / PSI.MINUTES_IN_HOUR
    # Initialize Container
    PSI.init_optimization_container!(container, PSI.CopperPlatePowerModel, sys)
    PSI.init_model_store_params!(decision_model)

    # Create Multiple Time Horizons based on ext horizons
    ext = PSY.get_ext(sys)
    dates_da = ext["λ_da_df"][!, "DateTime"]
    dates_rt = ext["λ_rt_df"][!, "DateTime"]
    len_DA = get(ext, "horizon_DA", length(dates_da))
    len_RT = get(ext, "horizon_RT", length(dates_rt))
    T_da = 1:len_DA
    T_rt = 1:len_RT
    container.time_steps = T_rt
    time_steps = T_rt

    # Map for DA to RT
    tmap = [div(k - 1, Int(length(T_rt) / length(T_da))) + 1 for k in T_rt]

    ###############################
    ######## Parameters ###########
    ###############################

    hybrids = collect(PSY.get_components(PSY.HybridSystem, sys))
    h_names = PSY.get_name.(hybrids)
    for h in hybrids
        PSY.get_ext(h)["T_da"] = T_da
        PSY.get_ext(h)["tmap"] = tmap
    end

    services = Set()
    for h in hybrids
        union!(services, PSY.get_services(h))
    end

    ###############################
    ######## Variables ############
    ###############################

    # Add Market variables
    for v in [EnergyDABidOut, EnergyDABidIn]
        PSI.add_variables!(container, v, hybrids, MerchantModelWithReserves())
    end

    for v in [EnergyRTBidOut, EnergyRTBidIn]
        PSI.add_variables!(container, v, hybrids, MerchantModelWithReserves())
    end

    # Add PCC Variables
    for v in
        [PSI.ActivePowerOutVariable, PSI.ActivePowerInVariable, PSI.ReservationVariable]
        PSI.add_variables!(container, v, hybrids, MerchantModelWithReserves())
    end

    # Add Reserve Variables
    for v in [BidReserveVariableOut, BidReserveVariableIn]
        PSI.add_variables!(container, v, hybrids, MerchantModelWithReserves())
    end

    # Add Reserve Up/Down Out/In Expression
    PSI.lazy_container_addition!(
        container,
        TotalReserveOutUpExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        TotalReserveOutDownExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        TotalReserveInUpExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        TotalReserveInDownExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    # Out Total Up
    add_to_expression!(
        container,
        TotalReserveOutUpExpression,
        BidReserveVariableOut,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # Out Total Down
    add_to_expression!(
        container,
        TotalReserveOutDownExpression,
        BidReserveVariableOut,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # In Total Up
    add_to_expression!(
        container,
        TotalReserveInUpExpression,
        BidReserveVariableIn,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # In Total Down
    add_to_expression!(
        container,
        TotalReserveInDownExpression,
        BidReserveVariableIn,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # Add Served Reserve Up/Down Out/In Expression
    PSI.lazy_container_addition!(
        container,
        ServedReserveOutUpExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        ServedReserveOutDownExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        ServedReserveInUpExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    PSI.lazy_container_addition!(
        container,
        ServedReserveInDownExpression(),
        T,
        PSY.get_name.(hybrids),
        T_da,
    )

    # Out Total Up
    add_to_expression!(
        container,
        ServedReserveOutUpExpression,
        BidReserveVariableOut,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # Out Total Down
    add_to_expression!(
        container,
        ServedReserveOutDownExpression,
        BidReserveVariableOut,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # In Total Up
    add_to_expression!(
        container,
        ServedReserveInUpExpression,
        BidReserveVariableIn,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # In Total Down
    add_to_expression!(
        container,
        ServedReserveInDownExpression,
        BidReserveVariableIn,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    ###############################
    ####### Parameters ############
    ###############################

    _hybrids_with_loads = [d for d in hybrids if PSY.get_electric_load(d) !== nothing]
    _hybrids_with_renewable = [d for d in hybrids if PSY.get_renewable_unit(d) !== nothing]
    _hybrids_with_storage = [d for d in hybrids if PSY.get_storage(d) !== nothing]
    _hybrids_with_thermal = [d for d in hybrids if PSY.get_thermal_unit(d) !== nothing]

    ## Renewable Variables and Expressions ##
    if !isempty(_hybrids_with_renewable)
        PSI.add_variables!(
            container,
            RenewablePower,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
        )
        PSI.add_variables!(
            container,
            EnergyRenewableBid,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
        )
        add_time_series_parameters!(
            container,
            RenewablePowerTimeSeries(),
            _hybrids_with_renewable,
            "RenewableDispatch__max_active_power_da",
        )
        PSI.add_variables!(
            container,
            RenewableReserveVariable,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
        )

        # Create renewable total up reserves
        PSI.lazy_container_addition!(
            container,
            RenewableReserveUpExpression(),
            T,
            PSY.get_name.(_hybrids_with_renewable),
            time_steps,
        )

        # Create renewable total down reserves
        PSI.lazy_container_addition!(
            container,
            RenewableReserveDownExpression(),
            T,
            PSY.get_name.(_hybrids_with_renewable),
            time_steps,
        )

        add_to_expression_componentreserveup!(
            container,
            RenewableReserveUpExpression,
            RenewableReserveVariable,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
            time_steps,
        )

        add_to_expression_componentreservedown!(
            container,
            RenewableReserveDownExpression,
            RenewableReserveVariable,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
            time_steps,
        )
    end

    ## Load Variables and Expressions ##
    if !isempty(_hybrids_with_loads)
        add_time_series_parameters!(
            container,
            ElectricLoadTimeSeries(),
            _hybrids_with_loads,
        )
        P_ld_container =
            PSI.get_parameter(container, ElectricLoadTimeSeries(), PSY.HybridSystem)
        P_ld_multiplier = PSI.get_parameter_multiplier_array(
            container,
            ElectricLoadTimeSeries(),
            PSY.HybridSystem,
        )
    end

    ## Storage Variables and Expressions ##
    if !isempty(_hybrids_with_storage)
        for v in [
            BatteryCharge,
            BatteryDischarge,
            PSI.EnergyVariable,
            BatteryStatus,
            ChargingReserveVariable,
            DischargingReserveVariable,
            EnergyBatteryChargeBid,
            EnergyBatteryDischargeBid,
        ]
            PSI.add_variables!(
                container,
                v,
                _hybrids_with_storage,
                MerchantModelWithReserves(),
            )
        end
        PSI.add_initial_condition!(
            container,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
            PSI.InitialEnergyLevel(),
        )

        # Add reserve expressions for charging unit
        PSI.lazy_container_addition!(
            container,
            ChargeReserveUpExpression(),
            T,
            PSY.get_name.(_hybrids_with_storage),
            time_steps,
        )

        PSI.lazy_container_addition!(
            container,
            ChargeReserveDownExpression(),
            T,
            PSY.get_name.(_hybrids_with_storage),
            time_steps,
        )

        add_to_expression_componentreserveup!(
            container,
            ChargeReserveUpExpression,
            ChargingReserveVariable,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
            time_steps,
        )

        add_to_expression_componentreservedown!(
            container,
            ChargeReserveDownExpression,
            ChargingReserveVariable,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
            time_steps,
        )

        # Add reserve expressions for discharging unit
        PSI.lazy_container_addition!(
            container,
            DischargeReserveUpExpression(),
            T,
            PSY.get_name.(_hybrids_with_storage),
            time_steps,
        )

        PSI.lazy_container_addition!(
            container,
            DischargeReserveDownExpression(),
            T,
            PSY.get_name.(_hybrids_with_storage),
            time_steps,
        )

        add_to_expression_componentreserveup!(
            container,
            DischargeReserveUpExpression,
            DischargingReserveVariable,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
            time_steps,
        )

        add_to_expression_componentreservedown!(
            container,
            DischargeReserveDownExpression,
            DischargingReserveVariable,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
            time_steps,
        )
    end

    if !isempty(_hybrids_with_thermal)
        for v in [ThermalPower, PSI.OnVariable, ThermalReserveVariable, EnergyThermalBid]
            PSI.add_variables!(
                container,
                v,
                _hybrids_with_thermal,
                MerchantModelWithReserves(),
            )
        end
        # Add Expressions for Thermal
        PSI.lazy_container_addition!(
            container,
            ThermalReserveUpExpression(),
            T,
            PSY.get_name.(_hybrids_with_thermal),
            time_steps,
        )

        PSI.lazy_container_addition!(
            container,
            ThermalReserveDownExpression(),
            T,
            PSY.get_name.(_hybrids_with_thermal),
            time_steps,
        )

        add_to_expression_componentreserveup!(
            container,
            ThermalReserveUpExpression,
            ThermalReserveVariable,
            _hybrids_with_thermal,
            MerchantModelWithReserves(),
            time_steps,
        )
        add_to_expression_componentreservedown!(
            container,
            ThermalReserveDownExpression,
            ThermalReserveVariable,
            _hybrids_with_thermal,
            MerchantModelWithReserves(),
            time_steps,
        )
    end

    ###############################
    ####### Obj. Function #########
    ###############################

    # This function add the parameters for both variables DABidOut and DABidIn
    PSI.add_parameters!(
        container,
        DayAheadEnergyPrice(),
        hybrids,
        MerchantModelWithReserves(),
    )

    λ_da_pos = PSI.get_parameter_array(
        container,
        DayAheadEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidOut",
    )

    λ_da_neg = PSI.get_parameter_array(
        container,
        DayAheadEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidIn",
    )

    # This function add the parameters for both variables RTBidOut and RTBidIn
    PSI.add_parameters!(
        container,
        RealTimeEnergyPrice(),
        hybrids,
        MerchantModelWithReserves(),
    )

    λ_rt_pos = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyRTBidOut",
    )

    λ_rt_neg = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyRTBidIn",
    )

    λ_dart_pos = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidOut",
    )

    λ_dart_neg = PSI.get_parameter_array(
        container,
        RealTimeEnergyPrice(),
        PSY.HybridSystem,
        "EnergyDABidIn",
    )

    # This function add the parameters for each Ancillary Service Variable (Out and In)
    PSI.add_parameters!(
        container,
        AncillaryServicePrice(),
        hybrids,
        MerchantModelWithReserves(),
    )

    # DA costs
    eb_da_out = PSI.get_variable(container, EnergyDABidOut(), PSY.HybridSystem)
    eb_da_in = PSI.get_variable(container, EnergyDABidIn(), PSY.HybridSystem)
    if !isempty(_hybrids_with_thermal)
        on_th = PSI.get_variable(container, PSI.OnVariable(), PSY.HybridSystem)
    end

    for t in T_da, dev in hybrids
        name = PSY.get_name(dev)
        lin_cost_da_out = Δt_DA * λ_da_pos[name, t] * eb_da_out[name, t]
        lin_cost_da_in = -Δt_DA * λ_da_neg[name, t] * eb_da_in[name, t]
        PSI.add_to_objective_variant_expression!(container, lin_cost_da_out)
        PSI.add_to_objective_variant_expression!(container, lin_cost_da_in)
        dev_services = PSY.get_services(dev)
        for service in dev_services
            service_name = PSY.get_name(service)
            price_service_out = PSI.get_parameter_array(
                container,
                AncillaryServicePrice(),
                PSY.HybridSystem,
                "BidReserveVariableOut_$(service_name)",
            )
            sb_service_out = PSI.get_variable(
                container,
                BidReserveVariableOut(),
                typeof(service),
                service_name,
            )
            price_service_in = PSI.get_parameter_array(
                container,
                AncillaryServicePrice(),
                PSY.HybridSystem,
                "BidReserveVariableIn_$(service_name)",
            )
            sb_service_in = PSI.get_variable(
                container,
                BidReserveVariableIn(),
                typeof(service),
                service_name,
            )
            service_out_cost = Δt_DA * price_service_out[name, t] * sb_service_out[name, t]
            service_in_cost = Δt_DA * price_service_in[name, t] * sb_service_in[name, t]
            PSI.add_to_objective_variant_expression!(container, service_out_cost)
            PSI.add_to_objective_variant_expression!(container, service_in_cost)
        end
        if !isnothing(dev.thermal_unit)
            # Workaround to add ThermalCost with a Linear Cost Since the model doesn't include PWL cost
            t_gen = dev.thermal_unit
            three_cost = PSY.get_operation_cost(t_gen)
            C_th_fix = three_cost.fixed # $/h
            lin_cost_on_th = -Δt_DA * C_th_fix * on_th[name, t]
            PSI.add_to_objective_invariant_expression!(container, lin_cost_on_th)
        end
    end

    # RT costs
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), PSY.HybridSystem)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), PSY.HybridSystem)

    # Thermal Variable Cost
    if !isempty(_hybrids_with_thermal)
        p_th = PSI.get_variable(container, ThermalPower(), PSY.HybridSystem)
    end
    # Renewable Cost
    # TODO: Decide if we include cost of curtailment or not
    # PSI.add_variable_cost!(container, RenewablePower(), _hybrids_with_renewable, MerchantModelWithReserves())
    # Battery Cost
    PSI.add_proportional_cost!(
        container,
        BatteryCharge(),
        _hybrids_with_storage,
        MerchantModelWithReserves(),
    )
    PSI.add_proportional_cost!(
        container,
        BatteryDischarge(),
        _hybrids_with_storage,
        MerchantModelWithReserves(),
    )

    # RT bids and DART arbitrage
    for t in T_rt, dev in hybrids
        name = PSY.get_name(dev)
        lin_cost_rt_out = Δt_RT * λ_rt_pos[name, t] * p_out[name, t]
        lin_cost_rt_in = -Δt_RT * λ_rt_neg[name, t] * p_in[name, t]
        lin_cost_dart_out = -Δt_RT * λ_dart_neg[name, t] * eb_da_out[name, tmap[t]]
        lin_cost_dart_in = Δt_RT * λ_dart_pos[name, t] * eb_da_in[name, tmap[t]]
        PSI.add_to_objective_variant_expression!(container, lin_cost_rt_out)
        PSI.add_to_objective_variant_expression!(container, lin_cost_rt_in)
        PSI.add_to_objective_variant_expression!(container, lin_cost_dart_out)
        PSI.add_to_objective_variant_expression!(container, lin_cost_dart_in)
        if !isnothing(dev.thermal_unit)
            t_gen = dev.thermal_unit
            three_cost = PSY.get_operation_cost(t_gen)
            first_part = three_cost.variable[1]
            second_part = three_cost.variable[2]
            slope = (second_part[1] - first_part[1]) / (second_part[2] - first_part[2]) # $/MWh
            fix_cost = three_cost.fixed # $/h
            C_th_var = slope * 100.0 # Multiply by 100 to transform to $/pu
            lin_cost_p_th = -Δt_RT * C_th_var * p_th[name, t]
            #PSI.add_to_objective_invariant_expression!(container, lin_cost_p_th)
        end
    end

    JuMP.@objective(
        container.JuMPmodel,
        MOI.MAX_SENSE,
        PSI.get_objective_function(container.objective_function)
    )

    add_expressions!(container, AssetPowerBalance, hybrids)

    ###############################
    ######## Constraints ##########
    ###############################

    # BidBalance
    constraint_eb_out = PSI.add_constraints_container!(
        container,
        BidBalanceOut(),
        PSY.HybridSystem,
        h_names,
        T_rt,
    )
    constraint_eb_in = PSI.add_constraints_container!(
        container,
        BidBalanceIn(),
        PSY.HybridSystem,
        h_names,
        T_rt,
    )

    # PCC Limits for Day-Ahead Bid Out
    add_constraints_dayaheadlimit_out_withreserves!(
        container,
        DayAheadBidOutRangeLimit,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # PCC Limits for Day-Ahead Bid In
    add_constraints_dayaheadlimit_in_withreserves!(
        container,
        DayAheadBidInRangeLimit,
        hybrids,
        MerchantModelWithReserves(),
        T_da,
    )

    # PCC Limits for Real-Time Bid Out
    add_constraints_realtimelimit_out_withreserves!(
        container,
        RealTimeBidOutRangeLimit,
        hybrids,
        MerchantModelWithReserves(),
        time_steps,
    )

    add_constraints_realtimelimit_in_withreserves!(
        container,
        RealTimeBidInRangeLimit,
        hybrids,
        MerchantModelWithReserves(),
        time_steps,
    )

    # Thermal
    if !isempty(_hybrids_with_thermal)
        # Thermal Limits with Reserves
        _add_thermallimit_withreserves!(
            container,
            ThermalReserveLimit,
            _hybrids_with_thermal,
            MerchantModelWithReserves(),
        )

        # Thermal Limit On without Reserves
        _add_constraints_thermalon_variableon!(
            container,
            ThermalOnVariableUb,
            _hybrids_with_thermal,
            MerchantModelWithReserves(),
        )

        # Thermal Limit Off without Reserves
        _add_constraints_thermalon_variableoff!(
            container,
            ThermalOnVariableLb,
            _hybrids_with_thermal,
            MerchantModelWithReserves(),
        )
    end
    # Battery Charging
    if !isempty(_hybrids_with_storage)
        # Discharging Limits with Reserves
        _add_constraints_discharging_reservelimit!(
            container,
            DischargingReservePowerLimit,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
        )

        # Discharging Limits without Reserves
        _add_constraints_batterydischargeon!(
            container,
            BatteryStatusDischargeOn,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
        )

        # Charging Limits with Reserves
        _add_constraints_charging_reservelimit!(
            container,
            ChargingReservePowerLimit,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
        )

        # Charging Limits without Reserve
        _add_constraints_batterychargeon!(
            container,
            BatteryStatusChargeOn,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
        )

        # Battery Balance
        _add_constraints_batterybalance!(
            container,
            BatteryBalance,
            _hybrids_with_storage,
            MerchantModelWithReserves(),
        )

        # TODO: set-up cycling in the decision model
        cycling = true
        if cycling
            _add_constraints_cyclingcharge!(
                container,
                CyclingCharge,
                _hybrids_with_storage,
                MerchantModelWithReserves(),
            )
            _add_constraints_cyclingdischarge!(
                container,
                CyclingDischarge,
                _hybrids_with_storage,
                MerchantModelWithReserves(),
            )
        end

        # Reserve Coverage
        for service in services
            _add_constraints_reservecoverage_withreserves!(
                container,
                ReserveCoverageConstraint,
                _hybrids_with_storage,
                service,
                MerchantModelWithReserves(),
            )
            _add_constraints_reservecoverage_withreserves_endofperiod!(
                container,
                ReserveCoverageConstraintEndOfPeriod,
                _hybrids_with_storage,
                service,
                MerchantModelWithReserves(),
            )
        end
    end

    if !isempty(_hybrids_with_renewable)
        # Add Renewable Limit without Reserves
        _add_constraints_renewablelimit!(
            container,
            RenewableActivePowerLimitConstraint,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
        )
        # Add Renewable Limit with Reserves
        _add_constraints_renewablereserve_limit!(
            container,
            RenewableReserveLimit,
            _hybrids_with_renewable,
            MerchantModelWithReserves(),
        )
    end

    # Asset Balance
    _add_constraints_energyassetbalance!(
        container,
        EnergyAssetBalance,
        hybrids,
        MerchantModelWithReserves(),
    )

    # Energy Bid Balance
    _add_constraints_energybidassetbalance!(
        container,
        EnergyBidAssetBalance,
        hybrids,
        MerchantModelWithReserves(),
    )

    # Reserve Bid Balance
    for service in services
        _add_constraints_reservebalance!(
            container,
            ReserveBalance,
            hybrids,
            service,
            MerchantModelWithReserves(),
            time_steps,
        )
    end

    # Status PCC Operation Out ON
    _add_constraints_statusout!(
        container,
        StatusOutOn,
        hybrids,
        MerchantModelWithReserves(),
    )

    # Status PCC Operation Out In
    _add_constraints_statusin!(container, StatusInOn, hybrids, MerchantModelWithReserves())

    # Market Convergence to Assets

    _add_constraints_out_marketconvergence!(
        container,
        MarketOutConvergence,
        hybrids,
        MerchantModelWithReserves(),
    )

    _add_constraints_in_marketconvergence!(
        container,
        MarketInConvergence,
        hybrids,
        MerchantModelWithReserves(),
    )

    ################################################
    ######## Dual Variables/Constraints ############
    ################################################

    # Add Duals for the EnergyBalance
    for v in [
        λUb,
        λLb,
        ComplementarySlackVarEnergyAssetBalanceUb,
        ComplementarySlackVarEnergyAssetBalanceLb,
    ]
        PSI.add_variables!(container, v, hybrids, MerchantModelWithReserves())
    end

    for c in [
        ComplementarySlacknessEnergyAssetBalanceUb,
        ComplementarySlacknessEnergyAssetBalanceLb,
    ]
        add_constraints!(container, c, hybrids, MerchantModelWithReserves())
    end

    ## Renewable Variables and Expressions ##
    if !isempty(_hybrids_with_renewable)
        for v in [
            μReUb,
            μReLb,
            ComplementarySlackVarRenewableActivePowerLimitConstraintUb,
            # Not needed due to 0.0 lower bound
            # ComplementarySlackVarRenewableActivePowerLimitConstraintLb,
        ]
            PSI.add_variables!(
                container,
                v,
                _hybrids_with_renewable,
                MerchantModelWithReserves(),
            )
        end

        for c in [
            OptConditionRenewablePower,
            ComplementarySlacknessRenewableActivePowerLimitConstraintUb,
            ComplementarySlacknessRenewableActivePowerLimitConstraintLb,
        ]
            add_constraints!(container, c, hybrids, MerchantModelWithReserves())
        end
    end

    ## Storage Variables and Expressions ##
    if !isempty(_hybrids_with_storage)
        for v in [
            μChUb,
            μChLb,
            μDsUb,
            μDsLb,
            γStBalLb,
            γStBalUb,
            νStUb,
            νStLb,
            κStDs,
            κStCh,
            ComplementarySlackVarBatteryStatusDischargeOnUb,
            # Not required since RenewableActivePower is lower bounded by 0.0
            # ComplementarySlackVarBatteryStatusDischargeOnLb,
            ComplementarySlackVarBatteryStatusChargeOnUb,
            # Not required since RenewableActivePower is lower bounded by 0.0
            # ComplementarySlackVarBatteryStatusChargeOnLb,
            ComplementarySlackVarBatteryBalanceUb,
            ComplementarySlackVarBatteryBalanceLb,
            ComplementarySlackVarEnergyLimitUb,
            # Not required since RenewableActivePower is lower bounded by 0.0
            # ComplementarySlackVarEnergyLimitLb,
            ComplementarySlackVarCyclingCharge,
            ComplementarySlackVarCyclingDischarge,
        ]
            PSI.add_variables!(
                container,
                v,
                _hybrids_with_storage,
                MerchantModelWithReserves(),
            )
        end

        for c in [
            OptConditionBatteryCharge,
            OptConditionBatteryDischarge,
            OptConditionEnergyVariable,
            ComplementarySlacknessBatteryStatusDischargeOnUb,
            ComplementarySlacknessBatteryStatusDischargeOnLb,
            ComplementarySlacknessBatteryStatusChargeOnUb,
            ComplementarySlacknessBatteryStatusChargeOnLb,
            ComplementarySlacknessBatteryBalanceUb,
            ComplementarySlacknessBatteryBalanceLb,
            ComplementarySlacknessEnergyLimitUb,
            ComplementarySlacknessEnergyLimitLb,
            ComplentarySlacknessCyclingCharge,
            ComplentarySlacknessCyclingDischarge,
        ]
            add_constraints!(container, c, hybrids, MerchantModelWithReserves())
        end
    end

    if !isempty(_hybrids_with_thermal)
        for v in [
            μThUb,
            μThLb,
            ComplementarySlackVarThermalOnVariableUb,
            ComplementarySlackVarThermalOnVariableLb,
        ]
            PSI.add_variables!(
                container,
                v,
                _hybrids_with_thermal,
                MerchantModelWithReserves(),
            )
        end

        for c in [
            OptConditionThermalPower,
            ComplementarySlacknessThermalOnVariableUb,
            ComplementarySlacknessThermalOnVariableLb,
        ]
            add_constraints!(container, c, hybrids, MerchantModelWithReserves())
        end
    end

    add_constraints!(container, StrongDualityCut, hybrids, MerchantModelWithReserves())

    PSI.serialize_metadata!(container, PSI.get_output_dir(decision_model))

    return
end

function PSI.update_decision_state!(
    state::PSI.SimulationState,
    key::PSI.VariableKey{T, PSY.HybridSystem},
    store_data::PSI.DenseAxisArray{Float64},
    simulation_time::Dates.DateTime,
    model_params::PSI.ModelStoreParams,
) where {T <: Union{EnergyDABidOut, EnergyDABidIn}}
    state_data = PSI.get_decision_state_data(state, key)
    model_resolution = PSI.get_resolution(model_params) # var res: 1 hour
    model_resolution = Dates.Hour(1) #TODO: Find a ext hack
    state_resolution = PSI.get_data_resolution(state_data) # 5 min
    resolution_ratio = model_resolution ÷ state_resolution
    state_timestamps = state_data.timestamps
    PSI.IS.@assert_op resolution_ratio >= 1

    if simulation_time > PSI.get_end_of_step_timestamp(state_data)
        state_data_index = 1
        state_data.timestamps[:] .=
            range(simulation_time; step=state_resolution, length=PSI.get_num_rows(state_data))
    else
        state_data_index = PSI.find_timestamp_index(state_timestamps, simulation_time)
    end

    offset = resolution_ratio - 1
    result_time_index = axes(store_data)[2]
    PSI.set_update_timestamp!(state_data, simulation_time)
    for t in result_time_index
        state_range = state_data_index:(state_data_index + offset)
        for name in axes(state_data.values)[1], i in state_range
            # TODO: We could also interpolate here
            state_data.values[name, i] = store_data[name, t]
        end
        PSI.set_last_recorded_row!(state_data, state_range[end])
        state_data_index += resolution_ratio
    end
    return
end

function PSI._update_parameter_values!(
    parameter_array::AbstractArray{T},
    attributes::PSI.VariableValueAttributes{
        PowerSimulations.VariableKey{U, PSY.HybridSystem},
    },
    ::Type{<:PSY.HybridSystem},
    model::PSI.DecisionModel,
    state::PSI.DatasetContainer{PSI.InMemoryDataset},
) where {T <: Union{JuMP.VariableRef, Float64}, U <: Union{EnergyDABidOut, EnergyDABidIn}}
    current_time = PSI.get_current_time(model)
    state_values = PSI.get_dataset_values(state, PSI.get_attribute_key(attributes))
    component_names, time = axes(parameter_array)
    resolution = PSI.get_resolution(model)
    state_data = PSI.get_dataset(state, PSI.get_attribute_key(attributes))
    state_timestamps = state_data.timestamps
    max_state_index = PSI.get_num_rows(state_data)
    state_data_index = PSI.find_timestamp_index(state_timestamps, current_time)
    sim_timestamps = range(current_time; step=resolution, length=time[end])
    for t in time
        if resolution < Dates.Minute(10)
            t_step = 1
        else
            t_step = 12
        end
        timestamp_ix = min(max_state_index, state_data_index + t_step)
        @debug "parameter horizon is over the step" max_state_index > state_data_index + 1
        if state_timestamps[timestamp_ix] <= sim_timestamps[t]
            state_data_index = timestamp_ix
        end
        for name in component_names
            # Pass indices in this way since JuMP DenseAxisArray don't support view()
            state_value = state_values[name, state_data_index]
            if !isfinite(state_value)
                error(
                    "The value for the system state used in $(PSI.encode_key_as_string(PSI.get_attribute_key(attributes))) is not a finite value $(state_value) \
                     This is commonly caused by referencing a state value at a time when such decision hasn't been made. \
                     Consider reviewing your models' horizon and interval definitions",
                )
            end
            PSI._set_param_value!(parameter_array, state_value, name, t)
        end
    end
    return
end

function PSI.add_feedforward_arguments!(
    container::PSI.OptimizationContainer,
    model::PSI.DeviceModel,
    devices::Vector{V},
) where {V <: PSY.HybridSystem}
    for ff in PSI.get_feedforwards(model)
        #@debug "arguments" ff V _group = LOG_GROUP_FEEDFORWARDS_CONSTRUCTION
        PSI._add_feedforward_arguments!(container, model, devices, ff)
    end
    return
end

function PSI._add_feedforward_arguments!(
    container::PSI.OptimizationContainer,
    model::PSI.DeviceModel,
    devices::Vector{T},
    ff::PSI.AbstractAffectFeedforward,
) where {T <: PSY.HybridSystem}
    parameter_type = PSI.get_default_parameter_type(ff, T)
    PSI.add_parameters!(container, parameter_type, ff, model, devices)
    return
end

function PSI._fix_parameter_value!(
    container::PSI.OptimizationContainer,
    parameter_array::PSI.JuMPFloatArray,
    parameter_attributes::PSI.VariableValueAttributes{
        PowerSimulations.VariableKey{U, PSY.HybridSystem},
    },
) where {U <: Union{EnergyDABidIn, EnergyDABidOut}}
    affected_variable_keys = parameter_attributes.affected_keys
    for var_key in affected_variable_keys
        variable = PSI.get_variable(container, var_key)
        component_name_var, time_var = axes(variable)
        component_names, time = axes(parameter_array)
        for t in time_var, name in component_names
            JuMP.fix(variable[name, t], parameter_array[name, t]; force=true)
        end
    end
    return
end
