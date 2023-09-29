###################################################################
################### Decision Model Parameters #####################
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
    parameter_multiplier = PSI.get_parameter_multiplier_array(container, key)
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


# Container for Total Reserve #
function PSI._add_parameters!(
    container::PSI.OptimizationContainer,
    ::T,
    key::PSI.VariableKey{TotalReserve, D},
    model::PSI.DeviceModel{D, W},
    devices::V,
) where {
    T <: PSI.FixValueParameter,
    V <: Union{Vector{D}, IS.FlattenIteratorWrapper{D}},
    W <: PSI.AbstractDeviceFormulation,
} where {D <: PSY.HybridSystem}
    @show "param for total reserve"
    var = PSI.get_variable(container, TotalReserve(), D)
    device_names, service_names, time_steps = axes(var)
    parameter_container =
        PSI.add_param_container!(container, T(), D, key, device_names, service_names, time_steps; meta = "$TotalReserve")
    jump_model = PSI.get_jump_model(container)
    for d in devices
        name = PSY.get_name(d)
        inital_parameter_value = 0.0
        for t in time_steps, service_name in service_names
            PSI.set_multiplier!(
                parameter_container,
                1.0,
                name,
                service_name,
                t,
            )
            PSI.set_parameter!(
                parameter_container,
                jump_model,
                inital_parameter_value,
                name,
                service_name,
                t,
            )
        end
    end
    return
end

function PSI._set_param_value!(param::AbstractArray, value::Float64, name::String, service_name::String, t::Int)
    param[name, service_name, t] = value
    #PSI.fix_parameter_value(param[name, service_name, t], value)
    return
end