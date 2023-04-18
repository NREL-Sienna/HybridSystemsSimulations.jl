PSI.get_variable_binary(
    ::PSI.VariableType,
    t::Type{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) = false
PSI.get_variable_binary(
    ::BatteryStatus,
    t::Type{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) = true
PSI.get_variable_binary(
    ::ThermalStatus,
    t::Type{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) = true
PSI.get_variable_binary(
    ::PSI.ReservationVariable,
    t::Type{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) = true

# Defined to avoid ambiguity
PSI.get_variable_binary(
    ::PSI.ActivePowerOutVariable,
    t::Type{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) = false
PSI.get_variable_binary(
    ::PSI.ActivePowerInVariable,
    t::Type{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) = false
PSI.get_variable_binary(
    ::ThermalPower,
    t::Type{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) = false
PSI.get_variable_binary(
    ::RenewablePower,
    t::Type{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) = false
PSI.get_variable_binary(
    ::BatteryCharge,
    t::Type{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) = false
PSI.get_variable_binary(
    ::BatteryDischarge,
    t::Type{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) = false
PSI.get_variable_binary(
    ::PSI.EnergyVariable,
    t::Type{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) = false

PSI.get_variable_lower_bound(
    ::EnergyDABidOut,
    d::PSY.HybridSystem,
    ::MerchantModelEnergyOnly,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyDABidOut,
    d::PSY.HybridSystem,
    ::MerchantModelEnergyOnly,
) = PSY.get_output_active_power_limits(d).max

PSI.get_variable_lower_bound(
    ::EnergyDABidIn,
    d::PSY.HybridSystem,
    ::MerchantModelEnergyOnly,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyDABidIn,
    d::PSY.HybridSystem,
    ::MerchantModelEnergyOnly,
) = PSY.get_output_active_power_limits(d).max

PSI.get_variable_lower_bound(
    ::EnergyRTBidOut,
    d::PSY.HybridSystem,
    ::MerchantModelEnergyOnly,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyRTBidOut,
    d::PSY.HybridSystem,
    ::MerchantModelEnergyOnly,
) = PSY.get_output_active_power_limits(d).max

PSI.get_variable_lower_bound(
    ::EnergyRTBidIn,
    d::PSY.HybridSystem,
    ::MerchantModelEnergyOnly,
) = 0.0
PSI.get_variable_upper_bound(
    ::EnergyRTBidIn,
    d::PSY.HybridSystem,
    ::MerchantModelEnergyOnly,
) = PSY.get_output_active_power_limits(d).max

function _get_row_val(df, row_name)
    return df[only(findall(==(row_name), df.ParamName)), :]["Value"]
end

function PSI.add_variables!(
    container::PSI.OptimizationContainer,
    ::Type{T},
    devices::Vector{PSY.HybridSystem},
    formulation::MerchantModelEnergyOnly,
) where {T <: Union{EnergyDABidOut, EnergyDABidIn}}
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
    formulation::MerchantModelEnergyOnly,
) where {T <: PSI.OnVariable}
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

function _add_time_series_parameters(
    container::PSI.OptimizationContainer,
    ts_name::String,
    param,
    devices::Vector{PSY.HybridSystem},
)
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

# Use correct PSI function
_get_multiplier(::Type{EnergyDABidOut}) = 1.0
_get_multiplier(::Type{EnergyDABidIn}) = -1.0
_get_multiplier(::Type{EnergyRTBidOut}) = 1.0
_get_multiplier(::Type{EnergyRTBidIn}) = -1.0

function _add_price_time_series_parameters(
    container::PSI.OptimizationContainer,
    param,
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
            price_value = λ[!, Bus_name] * 100.0 # Multiply by 100 to transform to $/pu
            name = PSY.get_name(device)
            for step in time_steps
                PSI.set_parameter!(
                    param_container,
                    jump_model,
                    price_value[step],
                    name,
                    step,
                )
                PSI.set_multiplier!(param_container, _get_multiplier(var), name, step)
            end
        end
    end
    return
end

function add_time_series_parameters!(
    container::PSI.OptimizationContainer,
    param::RenewablePowerTimeSeries,
    devices::Vector{PSY.HybridSystem},
)
    ts_name = "RenewableDispatch__max_active_power"
    _add_time_series_parameters(container, ts_name, param, devices)
end

function add_time_series_parameters!(
    container::PSI.OptimizationContainer,
    param::ElectricLoadTimeSeries,
    devices::Vector{PSY.HybridSystem},
)
    ts_name = "PowerLoad__max_active_power"
    _add_time_series_parameters(container, ts_name, param, devices)
    return
end

function PSI.add_parameters!(
    container::PSI.OptimizationContainer,
    param::T,
    devices::Vector{PSY.HybridSystem},
    ::MerchantModelEnergyOnly,
) where {T <: Union{DayAheadPrice, RealTimePrice}}
    add_time_series_parameters!(container, param, devices)
end

function add_time_series_parameters!(
    container::PSI.OptimizationContainer,
    param::DayAheadPrice,
    devices::Vector{PSY.HybridSystem},
)
    ts_key = "λ_da_df"
    vars = [EnergyDABidOut, EnergyDABidIn]
    _add_price_time_series_parameters(container, param, ts_key, devices, "horizon_DA", vars)
    return
end

function add_time_series_parameters!(
    container::PSI.OptimizationContainer,
    param::RealTimePrice,
    devices::Vector{PSY.HybridSystem},
)
    ts_key = "λ_rt_df"
    vars = [EnergyRTBidOut, EnergyRTBidIn]
    _add_price_time_series_parameters(container, param, ts_key, devices, "horizon_RT", vars)
    return
end

function _cost_function_unsynch(container::PSI.OptimizationContainer)
    if PSI.is_synchronized(container)
        obj_func = PSI.get_objective_function(container)
        PSI.set_synchronized_status(obj_func, false)
        PSI.reset_variant_terms(obj_func)
    end
    return
end

function _update_parameter_values!(
    model::PSI.DecisionModel{T},
    ::PSI.ParameterKey{RealTimePrice, PSY.HybridSystem},
    price_key::String,
) where {T <: HybridDecisionProblem}
    price_key = "λ_rt_df"
    _update_parameter_values!(model, key, price_key)
    return
end

function PSI.update_parameter_values!(
    model::PSI.DecisionModel{T},
    key::PSI.ParameterKey{DayAheadPrice, PSY.HybridSystem},
    decision_states::PSI.DatasetContainer{PSI.DataFrameDataset},
) where {T <: HybridDecisionProblem}
    price_key = "λ_da_df"
    _update_parameter_values!(model, key, price_key)
    return
end

function _update_parameter_values!(
    model::PSI.DecisionModel{T},
    key::PSI.ParameterKey{U, PSY.HybridSystem},
    price_key::String,
    horizon_key::String
) where {T <: HybridDecisionProblem, U}
    initial_forecast_time = PSI.get_current_time(model)
    container = PSI.get_optimization_container(model)
    parameter_array = PSI.get_parameter_array(container, key)
    attributes = PSI.get_parameter_attributes(container, key)
    _cost_function_unsynch(container)
    components = PSI.get_available_components(PSY.HybridSystem, PSI.get_system(model))
    for component in components
        ext = PSY.get_ext(component)
        horizon = ext[horizon_key]
        bus_name = PSY.get_name(PSY.get_bus(component))
        ix = PSI.find_timestamp_index(ext[price_key][!, "DateTime"], initial_forecast_time)
        λ = ext[price_key][!, bus_name][ix:(ix + horizon - 1)]
        name = PSY.get_name(component)
        for (t, value) in enumerate(λ)
            PSI._set_param_value!(parameter_array, value, name, t)
            PSI.update_variable_cost!(container, parameter_array, attributes, component, t)
        end
    end
    return
end

function _update_parameter_values!(
    model::PSI.DecisionModel{T},
    key::PSI.ParameterKey{DayAheadPrice, PSY.HybridSystem},
    price_key::String,
) where {T <: HybridDecisionProblem}
    _update_parameter_values!(model, key, price_key, "horizon_DA")
    return
end

function _update_parameter_values!(
    model::PSI.DecisionModel{T},
    key::PSI.ParameterKey{RealTimePrice, PSY.HybridSystem},
    price_key::String,
) where {T <: HybridDecisionProblem}
    _update_parameter_values!(model, key, price_key, "horizon_RT")
    return
end

function PSI.build_impl!(decision_model::PSI.DecisionModel{MerchantHybridEnergyCase})
    container = PSI.get_optimization_container(decision_model)
    model = container.JuMPmodel
    sys = PSI.get_system(decision_model)
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

    # Map for DA to RT
    tmap = [div(k - 1, Int(length(T_rt) / length(T_da))) + 1 for k in T_rt]

    ###############################
    ######## Parameters ###########
    ###############################

    hybrids = collect(PSY.get_components(PSY.HybridSystem, sys))
    h_names = PSY.get_name.(hybrids)
    for h in hybrids
        PSY.get_ext(h)["T_da"] = T_da
    end
    #P_max_pcc = PSY.get_output_active_power_limits(h).max

    # Thermal Params
    #t_gen = h.thermal_unit
    #P_min_th, P_max_th = PSY.get_active_power_limits(t_gen)
    #three_cost = PSY.get_operation_cost(t_gen)
    #first_part = three_cost.variable[1]
    #second_part = three_cost.variable[2]
    #slope = (second_part[1] - first_part[1]) / (second_part[2] - first_part[2]) # $/MWh
    #fix_cost = three_cost.fixed # $/h
    #C_th_var = slope * 100.0 # Multiply by 100 to transform to $/pu
    #C_th_fix = fix_cost

    # Battery Params
    #storage = h.storage
    #P_ch_max = PSY.get_input_active_power_limits(storage).max
    #P_ds_max = PSY.get_output_active_power_limits(storage).max
    #η_ch = storage.efficiency.in
    #η_ds = storage.efficiency.out
    #inv_η_ds = 1.0 / η_ds
    #E_min, E_max = PSY.get_state_of_charge_limits(storage)
    #E0 = storage.initial_energy

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
    for v in [
        ThermalPower,
        PSI.OnVariable,
        RenewablePower,
        BatteryCharge,
        BatteryDischarge,
        PSI.EnergyVariable,
        BatteryStatus,
    ]
        PSI.add_variables!(container, v, hybrids, MerchantModelEnergyOnly())
    end

    ###############################
    ####### Parameters ############
    ###############################

    _hybrids_with_loads = [d for d in hybrids if PSY.get_electric_load(d) !== nothing]
    _hybrids_with_renewable = [d for d in hybrids if PSY.get_renewable_unit(d) !== nothing]
    _hybrids_with_storage = [d for d in hybrids if PSY.get_storage(d) !== nothing]
    _hybrids_with_thermal = [d for d in hybrids if PSY.get_thermal_unit(d) !== nothing]

    if !isempty(_hybrids_with_renewable)
        add_time_series_parameters!(
            container,
            RenewablePowerTimeSeries(),
            _hybrids_with_renewable,
        )
    end
    if !isempty(_hybrids_with_loads)
        add_time_series_parameters!(
            container,
            ElectricLoadTimeSeries(),
            _hybrids_with_loads,
        )
    end

    if !isempty(_hybrids_with_storage)
        PSI.add_initial_condition!(
            container,
            _hybrids_with_storage,
            MerchantModelEnergyOnly(),
            PSI.InitialEnergyLevel(),
        )
    end

    P_ld_container =
        PSI.get_parameter(container, ElectricLoadTimeSeries(), PSY.HybridSystem)
    P_ld_multiplier = PSI.get_parameter_multiplier_array(
        container,
        ElectricLoadTimeSeries(),
        PSY.HybridSystem,
    )

    ###############################
    ####### Obj. Function #########
    ###############################

    # This function add the parameters for both variables DABidOut and DABidIn
    PSI.add_parameters!(container, DayAheadPrice(), hybrids, MerchantModelEnergyOnly())

    λ_da_pos = PSI.get_parameter_array(
        container,
        DayAheadPrice(),
        PSY.HybridSystem,
        "EnergyDABidOut",
    )

    λ_da_neg = PSI.get_parameter_array(
        container,
        DayAheadPrice(),
        PSY.HybridSystem,
        "EnergyDABidIn",
    )

    # This function add the parameters for both variables RTBidOut and RTBidIn
    PSI.add_parameters!(container, RealTimePrice(), hybrids, MerchantModelEnergyOnly())

    λ_rt_pos = PSI.get_parameter_array(
        container,
        RealTimePrice(),
        PSY.HybridSystem,
        "EnergyRTBidOut",
    )

    λ_rt_neg = PSI.get_parameter_array(
        container,
        RealTimePrice(),
        PSY.HybridSystem,
        "EnergyRTBidIn",
    )

    # DA costs
    eb_da_out = PSI.get_variable(container, EnergyDABidOut(), PSY.HybridSystem)
    eb_da_in = PSI.get_variable(container, EnergyDABidIn(), PSY.HybridSystem)
    on_th = PSI.get_variable(container, PSI.OnVariable(), PSY.HybridSystem)

    for t in T_da, dev in hybrids
        name = PSY.get_name(dev)
        lin_cost_da_out = Δt_DA * λ_da_pos[name, t] * eb_da_out[name, t]
        lin_cost_da_in = -Δt_DA * λ_da_neg[name, t] * eb_da_in[name, t]
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
    p_th = PSI.get_variable(container, ThermalPower(), PSY.HybridSystem)
    p_re = PSI.get_variable(container, RenewablePower(), PSY.HybridSystem)
    p_ch = PSI.get_variable(container, BatteryCharge(), PSY.HybridSystem)
    p_ds = PSI.get_variable(container, BatteryDischarge(), PSY.HybridSystem)
    e_st = PSI.get_variable(container, PSI.EnergyVariable(), PSY.HybridSystem)
    status_st = PSI.get_variable(container, BatteryStatus(), PSY.HybridSystem)

    for t in T_rt, dev in hybrids
        name = PSY.get_name(dev)
        lin_cost_rt_out = Δt_RT * λ_rt_pos[name, t] * eb_rt_out[name, t]
        lin_cost_rt_in = -Δt_RT * λ_rt_neg[name, t] * eb_rt_in[name, t]
        lin_cost_dart_out = -Δt_RT * λ_rt_neg[name, t] * eb_da_out[name, tmap[t]]
        lin_cost_dart_in = Δt_RT * λ_rt_pos[name, t] * eb_da_in[name, tmap[t]]
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
    constraint_thermal_on = PSI.add_constraints_container!(
        container,
        ThermalOnVariableOn(),
        PSY.HybridSystem,
        h_names,
        T_rt,
    )

    constraint_thermal_off = PSI.add_constraints_container!(
        container,
        ThermalOnVariableOff(),
        PSY.HybridSystem,
        h_names,
        T_rt,
    )
    # Battery Charging
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
            P_ld_array = PSI.get_parameter_column_refs(P_ld_container, name)
            constraint_balance[name, t] = JuMP.@constraint(
                model,
                p_th[name, t] + p_re[name, t] + p_ds[name, t] - p_ch[name, t] -
                P_ld_array[t] * P_ld_multiplier[name, t] - p_out[name, t] +
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
        E_min, E_max = PSY.get_state_of_charge_limits(storage)
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
    return
end

function PSI.build_impl!(decision_model::PSI.DecisionModel{MerchantHybridEnergyFixedDA})
    container = PSI.get_optimization_container(decision_model)
    model = container.JuMPmodel
    sys = PSI.get_system(decision_model)
    RT_resolution = PSY.get_time_series_resolution(sys)
    PSI.init_optimization_container!(container, CopperPlatePowerModel, sys)
    PSI.init_model_store_params!(decision_model)
    ext = PSY.get_ext(sys)

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

    h = PSY.get_component(PSY.HybridSystem, sys, "317_Hybrid")
    P_max_pcc = PSY.get_output_active_power_limits(h).max
    VOM = h.storage.operation_cost.variable.cost
    Δt_DA = 1.0
    starttime = Dates.DateTime("2020-10-03T00:00:00")
    Δt_RT = Dates.value(Dates.Minute(RT_resolution)) / PSI.MINUTES_IN_HOUR
    Cycles = CYCLES_PER_DAY * Δt_RT * length(T_rt) / HOURS_IN_DAY
    Bus_name = "Chuhsi"

    # Thermal Params
    t_gen = h.thermal_unit
    P_min_th, P_max_th = PSY.get_active_power_limits(t_gen)
    three_cost = PSY.get_operation_cost(t_gen)
    first_part = three_cost.variable[1]
    second_part = three_cost.variable[2]
    slope = (second_part[1] - first_part[1]) / (second_part[2] - first_part[2]) # $/MWh
    fix_cost = three_cost.fixed # $/h
    C_th_var = slope * 100.0 # Multiply by 100 to transform to $/pu
    C_th_fix = fix_cost

    # Battery Params
    storage = h.storage
    P_ch_max = PSY.get_input_active_power_limits(storage).max
    P_ds_max = PSY.get_output_active_power_limits(storage).max
    η_ch = storage.efficiency.in
    η_ds = storage.efficiency.out
    inv_η_ds = 1.0 / η_ds
    E_min, E_max = PSY.get_state_of_charge_limits(storage)
    E0 = storage.initial_energy

    # Renewable Forecast
    ta_ren = PSY.get_time_series_array(
        PSY.SingleTimeSeries,
        h,
        "RenewableDispatch__max_active_power",
        start_time=starttime,
        len=T_rt[end],
    )
    multiplier_ren = values(ta_ren) / PSY.get_max_active_power(h)
    P_re_star = multiplier_ren * PSY.get_max_active_power(h.renewable_unit)

    # Load Forecast
    ta_load = PSY.get_time_series_array(
        PSY.SingleTimeSeries,
        h,
        "PowerLoad__max_active_power",
        start_time=starttime,
        len=T_rt[end],
    )
    multiplier_load = values(ta_load) / PSY.get_max_active_power(h)
    P_ld = multiplier_load * PSY.get_max_active_power(h.electric_load)

    # Forecast Prices
    λ_da = ext["λ_da_df"][!, Bus_name] * 100.0 # Multiply by 100 to transform to $/pu
    λ_rt = ext["λ_rt_df"][!, Bus_name] * 100.0 # Multiply by 100 to transform to $/pu

    # Bids
    da_bid_out_fix = ext["bid_df"][!, "BidOut"]
    da_bid_in_fix = ext["bid_df"][!, "BidIn"]

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
        JuMP.fix.(eb_da_out[t], da_bid_out_fix[t], force=true)
        JuMP.fix.(eb_da_in[t], da_bid_in_fix[t], force=true)
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
        ThermalOnVariableOn(),
        PSY.HybridSystem,
        T_rt,
    )

    constraint_thermal_off = PSI.add_constraints_container!(
        container,
        ThermalOnVariableOff(),
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
    #JuMP.fix.(on_th, 0, force=true)
    return
end

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
        ThermalOnVariableOn(),
        PSY.HybridSystem,
        T_rt,
    )

    constraint_thermal_off = PSI.add_constraints_container!(
        container,
        ThermalOnVariableOff(),
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
        ThermalOnVariableOn(),
        PSY.HybridSystem,
        T_rt,
    )
    constraint_thermal_off = PSI.add_constraints_container!(
        container,
        ThermalOnVariableOff(),
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
        #@show t
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
