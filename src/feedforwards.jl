struct CyclingChargeLimitFeedforward <: PSI.AbstractAffectFeedforward
    optimization_container_key::PSI.OptimizationContainerKey
    affected_values::Vector{<:PSI.OptimizationContainerKey}
    target_period::Int
    penalty_cost::Float64
    function CyclingLimitFeedforward(;
        component_type::Type{<:PSY.Component},
        source::Type{T},
        affected_values::Vector{DataType},
        target_period::Int,
        penalty_cost::Float64,
        meta=PSI.CONTAINER_KEY_EMPTY_META,
    ) where {T}
        values_vector = Vector{PSI.VariableKey}(undef, length(affected_values))
        for (ix, v) in enumerate(affected_values)
            if v <: PSI.VariableType
                values_vector[ix] =
                    PSI.get_optimization_container_key(v(), component_type, meta)
            else
                error(
                    "ReservoirTargetFeedforward is only compatible with VariableType or ParamterType affected values",
                )
            end
        end
        new(
            PSI.get_optimization_container_key(T(), component_type, meta),
            values_vector,
            penalty_cost,
        )
    end
end

PSI.get_default_parameter_type(::CyclingChargeLimitFeedforward, _) =
    CyclingChargeLimitParameter
PSI.get_optimization_container_key(ff::CyclingChargeLimitFeedforward) =
    ff.optimization_container_key

function PSI.update_parameter_values!(
    model::PSI.DecisionModel,
    key::PSI.ParameterKey{T, U},
    input::PSI.DatasetContainer{PSI.InMemoryDataset},
) where {
    T <: Union{CyclingChargeLimitParameter, CyclingDischargeLimitParameter},
    U <: PSY.HybridSystem,
}
    # Enable again for detailed debugging
    # TimerOutputs.@timeit RUN_SIMULATION_TIMER "$T $U Parameter Update" begin
    optimization_container = PSI.get_optimization_container(model)
    # Note: Do not instantite a new key here because it might not match the param keys in the container
    # if the keys have strings in the meta fields
    parameter_array = PSI.get_parameter_array(optimization_container, key)
    parameter_attributes = PSI.get_parameter_attributes(optimization_container, key)
    current_time = PSI.get_current_time(model)
    state_values =
        PSI.get_dataset_values(input, PSI.get_attribute_key(parameter_attributes))
    component_names = axes(parameter_array)[1]
    resolution = PSI.get_resolution(model)
    #TODO: This should be Horizon Time Steps not Interval
    interval_time_steps =
        Int(PSI.get_interval(model.internal.store_parameters) / resolution)
    state_data = PSI.get_dataset(input, PSI.get_attribute_key(parameter_attributes))
    state_timestamps = state_data.timestamps
    state_data_index = PSI.find_timestamp_index(state_timestamps, current_time)
    for name in component_names
        PSI.fix_parameter_value(
            parameter_array[name],
            state_values[name, state_data_index + interval_time_steps - 1],
        )
    end

    IS.@record :execution PSI.ParameterUpdateEvent(
        T,
        U,
        parameter_attributes,
        PSI.get_current_timestamp(model),
        PSI.get_name(model),
    )
    return
end
