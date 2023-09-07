# Add TotalBidReserve
function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{W},
    devices::Vector{PSY.HybridSystem},
    formulation::MerchantModelWithReserves,
) where {W <: TotalBidReserve}
    @assert !isempty(devices)
    time_steps = PSY.get_ext(first(devices))["T_da"]
    # TODO
    # Best way to create this variable? We need to have all services and its type.
    services = Set()
    for d in devices
        union!(services, PSY.get_services(d))
    end

    for service in services
        PSI.add_aux_variable_container!(
            container,
            W(),
            typeof(service),
            PSY.get_name.(devices),
            time_steps;
            meta=PSY.get_name(service),
        )
    end

    return
end

function PSI.calculate_aux_variable_value!(
    container::PSI.OptimizationContainer,
    ::PSI.AuxVarKey{HybridSystemsSimulations.TotalBidReserve, T},
    system::PSY.System,
) where {T <: PSY.VariableReserve}
    devices = PSI.get_available_components(PSY.HybridSystem, system)
    time_steps = PSY.get_ext(first(devices))["T_da"]
    services = Set()
    for h in devices
        union!(services, PSY.get_services(h))
    end
    for service in services
        V = typeof(service)
        service_name = PSY.get_name(service)
        res_out = PSI.get_variable(container, BidReserveVariableOut(), V, service_name)
        res_in = PSI.get_variable(container, BidReserveVariableIn(), V, service_name)
        tot_res = PSI.get_aux_variable(container, TotalBidReserve(), V, service_name)
        for d in devices, t in time_steps
            name = PSY.get_name(d)
            tot_res[name, t] = PSI.jump_value(res_out[name, t]) + PSI.jump_value(res_in[name, t])
        end
    end

    return
end