###########################################################
### ReserveUp/ReserveDown Upper/Lower Limit Expressions ###
###########################################################

# ReserveUp Upper/Lower Limit Expression
function add_to_expression_totalreserveup!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::W,
) where {
    T <: TotalReserveUpExpression,
    U <: PSI.VariableType,
    V <: PSY.HybridSystem,
    W <: AbstractHybridFormulation,
}
    expression = PSI.get_expression(container, T(), V)
    for d in devices
        name = PSY.get_name(d)
        services = PSY.get_services(d)
        for service in services
            if isa(service, PSY.Reserve{PSY.ReserveDown})
                continue
            end
            # TODO: This could be improved without requiring to read services for each component independently
            variable =
                PSI.get_variable(container, U(), typeof(service), PSY.get_name(service))
            mult = PSI.get_variable_multiplier(U, d, W(), service)
            for t in PSI.get_time_steps(container)
                PSI._add_to_jump_expression!(expression[name, t], variable[name, t], mult)
            end
        end
    end
    return
end

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    expression::Type{T},
    variable::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: TotalReserveUpExpression,
    U <: PSI.VariableType,
    V <: PSY.HybridSystem,
    W <: HybridDispatchWithReserves,
    X <: PM.AbstractPowerModel,
}
    add_to_expression_totalreserveup!(container, expression, variable, devices, W())
    return
end

# ReserveDown Upper/Lower Limit Expression
function add_to_expression_totalreservedown!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::W,
) where {
    T <: TotalReserveDownExpression,
    U <: PSI.VariableType,
    V <: PSY.HybridSystem,
    W <: AbstractHybridFormulation,
}
    expression = PSI.get_expression(container, T(), V)
    for d in devices
        name = PSY.get_name(d)
        services = PSY.get_services(d)
        for service in services
            if isa(service, PSY.Reserve{PSY.ReserveUp})
                continue
            end
            # TODO: This could be improved without requiring to read services for each component independently
            variable =
                PSI.get_variable(container, U(), typeof(service), PSY.get_name(service))
            mult = PSI.get_variable_multiplier(U, d, W(), service)
            for t in PSI.get_time_steps(container)
                PSI._add_to_jump_expression!(expression[name, t], variable[name, t], mult)
            end
        end
    end
    return
end

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    expression::Type{T},
    variable::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: TotalReserveDownExpression,
    U <: PSI.VariableType,
    V <: PSY.HybridSystem,
    W <: HybridDispatchWithReserves,
    X <: PM.AbstractPowerModel,
}
    add_to_expression_totalreservedown!(container, expression, variable, devices, W())
    return
end

# Component Reserve Up
function add_to_expression_componentreserveup!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::W,
) where {
    T <: ComponentReserveUpExpressionType,
    U <: PSI.VariableType,
    V <: PSY.HybridSystem,
    W <: AbstractHybridFormulation,
}
    expression = PSI.get_expression(container, T(), V)
    for d in devices
        name = PSY.get_name(d)
        services = PSY.get_services(d)
        for service in services
            # TODO: This could be improved without requiring to read services for each component independently
            if isa(service, PSY.Reserve{PSY.ReserveDown})
                continue
            end
            variable =
                PSI.get_variable(container, U(), typeof(service), PSY.get_name(service))
            mult = PSI.get_variable_multiplier(U, d, W(), service)
            for t in PSI.get_time_steps(container)
                PSI._add_to_jump_expression!(expression[name, t], variable[name, t], mult)
            end
        end
    end
    return
end

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    expression::Type{T},
    variable::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: ComponentReserveUpExpressionType,
    U <: PSI.VariableType,
    V <: PSY.HybridSystem,
    W <: HybridDispatchWithReserves,
    X <: PM.AbstractPowerModel,
}
    add_to_expression_componentreserveup!(container, expression, variable, devices, W())
    return
end

# Component Reserve Down
function add_to_expression_componentreservedown!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::W,
) where {
    T <: ComponentReserveDownExpressionType,
    U <: PSI.VariableType,
    V <: PSY.HybridSystem,
    W <: AbstractHybridFormulation,
}
    expression = PSI.get_expression(container, T(), V)
    for d in devices
        name = PSY.get_name(d)
        services = PSY.get_services(d)
        for service in services
            # TODO: This could be improved without requiring to read services for each component independently
            if isa(service, PSY.Reserve{PSY.ReserveUp})
                continue
            end
            variable =
                PSI.get_variable(container, U(), typeof(service), PSY.get_name(service))
            mult = PSI.get_variable_multiplier(U, d, W(), service)
            for t in PSI.get_time_steps(container)
                PSI._add_to_jump_expression!(expression[name, t], variable[name, t], mult)
            end
        end
    end
    return
end

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    expression::Type{T},
    variable::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: ComponentReserveDownExpressionType,
    U <: PSI.VariableType,
    V <: PSY.HybridSystem,
    W <: HybridDispatchWithReserves,
    X <: PM.AbstractPowerModel,
}
    add_to_expression_componentreservedown!(container, expression, variable, devices, W())
    return
end

# Add Reserve Variable for each component to the Reserve Balance
function add_to_expression_componentreservebalance!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::W,
) where {
    T <: ComponentReserveBalanceExpression,
    U <: ComponentReserveVariableType,
    V <: PSY.HybridSystem,
    W <: AbstractHybridFormulation,
}
    for d in devices
        name = PSY.get_name(d)
        services = PSY.get_services(d)
        expression = PSI.get_expression(container, T(), V)
        for service in services
            # TODO: This could be improved without requiring to read services for each component independently
            service_type = typeof(service)
            service_name = PSY.get_name(service)
            variable = PSI.get_variable(container, U(), service_type, service_name)
            for t in PSI.get_time_steps(container)
                expression[name, t]
                variable[service_name, t]
                PSI._add_to_jump_expression!(
                    expression[name, t],
                    variable[service_name, t],
                    1.0,
                )
            end
        end
    end
    return
end

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    expression::Type{T},
    variable::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: ComponentReserveBalanceExpression,
    U <: ComponentReserveVariableType,
    V <: PSY.HybridSystem,
    W <: HybridDispatchWithReserves,
    X <: PM.AbstractPowerModel,
}
    add_to_expression_componentreservebalance!(
        container,
        expression,
        variable,
        devices,
        W(),
    )
    return
end

# Add Total ReserveOut and ReserveIn to the Reserve Balance
function add_to_expression_totalreservebalance!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    ::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::W,
) where {
    T <: ComponentReserveBalanceExpression,
    U <: Union{ReserveVariableOut, ReserveVariableIn},
    V <: PSY.HybridSystem,
    W <: AbstractHybridFormulation,
}
    for d in devices
        name = PSY.get_name(d)
        services = PSY.get_services(d)
        for service in services
            # TODO: This could be improved without requiring to read services for each component independently
            service_type = typeof(service)
            service_name = PSY.get_name(service)
            variable = PSI.get_variable(container, U(), service_type, service_name)
            expression = PSI.get_expression(container, T(), V)
            mult = PSI.get_variable_multiplier(U, d, W(), service)
            for t in PSI.get_time_steps(container)
                PSI._add_to_jump_expression!(
                    expression[service_name, t],
                    variable[name, t],
                    mult,
                )
            end
        end
    end
    return
end

function PSI.add_to_expression!(
    container::PSI.OptimizationContainer,
    expression::Type{T},
    variable::Type{U},
    devices::Union{Vector{V}, IS.FlattenIteratorWrapper{V}},
    ::PSI.DeviceModel{V, W},
    ::PSI.NetworkModel{X},
) where {
    T <: ComponentReserveBalanceExpression,
    U <: Union{ReserveVariableOut, ReserveVariableIn},
    V <: PSY.HybridSystem,
    W <: HybridDispatchWithReserves,
    X <: PM.AbstractPowerModel,
}
    add_to_expression_totalreservebalance!(container, expression, variable, devices, W())
    return
end
