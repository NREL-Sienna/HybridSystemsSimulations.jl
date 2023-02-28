import MathOptInterface
const MOI = MathOptInterface

function add_variable!(
    decision_model::DecisionModel{HybridOptimizer},
    type::T,
    time_range,
    lb,
    ub::Float64,
) where {T <: PSI.VariableType}
    name = string(type)[1:(end - 2)]
    container = PSI.get_optimization_container(decision_model)
    model = PSI.get_jump_model(decision_model)
    var = PSI.add_variable_container!(container, type, HybridSystem, time_range)
    for t in time_range
        var[t] = JuMP.@variable(
            model,
            base_name = "$(name)_$(t)",
            lower_bound = lb,
            upper_bound = ub
        )
    end
    return
end

function add_variable!(
    decision_model::DecisionModel{HybridOptimizer},
    type::T,
    time_range,
    lb,
    ub::Vector{Float64},
) where {T <: PSI.VariableType}
    name = string(type)[1:(end - 2)]
    container = PSI.get_optimization_container(decision_model)
    model = PSI.get_jump_model(decision_model)
    var = PSI.add_variable_container!(container, type, HybridSystem, time_range)
    for t in time_range
        var[t] = JuMP.@variable(
            model,
            base_name = "$(name)_$(t)",
            lower_bound = lb,
            upper_bound = ub[t]
        )
    end
    return
end

function add_binary_variable!(
    decision_model::DecisionModel{HybridOptimizer},
    type::T,
    time_range,
) where {T <: PSI.VariableType}
    name = string(type)[1:(end - 2)]
    container = PSI.get_optimization_container(decision_model)
    model = PSI.get_jump_model(decision_model)
    var = PSI.add_variable_container!(container, type, HybridSystem, time_range)
    for t in time_range
        var[t] = JuMP.@variable(model, base_name = "$(name)_$(t)", binary = true)
    end
    return
end

function PSI.build_impl!(decision_model::DecisionModel{HybridOptimizer})
    container = PSI.get_optimization_container(decision_model)
    #settings = PSI.get_settings(container)
    model = container.JuMPmodel
    s = PSI.get_system(decision_model)
    PSI.init_optimization_container!(container, CopperPlatePowerModel, s)
    PSI.init_model_store_params!(decision_model)
    ext = get_ext(s)
    ###############################
    ######## Create Sets ##########
    ###############################

    dates_da = ext["λ_da_df"][!, "DateTime"]
    dates_rt = ext["λ_rt_df"][!, "DateTime"]
    T_da = 1:length(dates_da)
    T_rt = 1:length(dates_rt)
    container.time_steps = T_rt

    tmap = [div(k - 1, Int(length(T_rt) / length(T_da))) + 1 for k in T_rt]
    T_end = T_rt[end]
    #set_horizon!(settings, T_end)

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
    P_max_th = get_row_val(ext["th_df"], "P_max")
    P_min_th = get_row_val(ext["th_df"], "P_min")
    C_th_var = get_row_val(ext["th_df"], "C_var") * 100.0 # Multiply by 100 to transform to $/pu
    C_th_fix = get_row_val(ext["th_df"], "C_fix")

    # Battery Params
    P_ch_max = get_row_val(ext["b_df"], "P_ch_max")
    P_ds_max = get_row_val(ext["b_df"], "P_ds_max")
    η_ch = get_row_val(ext["b_df"], "η_in")
    η_ds = get_row_val(ext["b_df"], "η_out")
    inv_η_ds = 1.0 / η_ds
    E_max = get_row_val(ext["b_df"], "SoC_max")
    E_min = get_row_val(ext["b_df"], "SoC_min")
    E0 = get_row_val(ext["b_df"], "initial_energy")

    # Renewable Forecast
    P_re_star = ext["P_rt"][!, "MaxPower"]

    # Load Forecast
    P_ld = ext["Pload_rt"][!, "MaxPower"] * 0.0

    # Forecast Prices
    λ_da = ext["λ_da_df"][!, Bus_name] * 100.0 # Multiply by 100 to transform to $/pu
    λ_rt = ext["λ_rt_df"][!, Bus_name] * 100.0 # Multiply by 100 to transform to $/pu

    # Add Market variables
    add_variable!(decision_model, energyDABidOut(), T_da, 0.0, P_max_pcc)
    add_variable!(decision_model, energyDABidIn(), T_da, 0.0, P_max_pcc)
    add_variable!(decision_model, energyRTBidOut(), T_rt, 0.0, P_max_pcc)
    add_variable!(decision_model, energyRTBidIn(), T_rt, 0.0, P_max_pcc)

    # Add PCC Variables
    add_variable!(decision_model, HybridPowerOut(), T_rt, 0.0, P_max_pcc)
    add_variable!(decision_model, HybridPowerIn(), T_rt, 0.0, P_max_pcc)
    add_binary_variable!(decision_model, HybridStatus(), T_rt)

    # Add Thermal Vars: No Thermal For now
    #add_variable!(decision_model, ThermalPower(), T_rt, 0.0, P_max_th)
    #add_binary_variable!(decision_model, ThermalStatus(), T_da)

    # Add Renewable Variables
    add_variable!(decision_model, RenewablePower(), T_rt, 0.0, P_re_star)

    # Add Battery Variables
    add_variable!(decision_model, BatteryCharge(), T_rt, 0.0, P_ch_max)
    add_variable!(decision_model, BatteryDischarge(), T_rt, 0.0, P_ds_max)
    add_variable!(decision_model, BatteryStateOfCharge(), T_rt, E_min, E_max)
    add_binary_variable!(decision_model, BatteryStatus(), T_rt)

    ###############################
    ####### Obj. Function #########
    ###############################

    # DA costs
    eb_da_out = PSI.get_variable(container, energyDABidOut(), HybridSystem)
    eb_da_in = PSI.get_variable(container, energyDABidIn(), HybridSystem)
    #on_th = PSI.get_variable(container, ThermalStatus(), HybridSystem)

    for t in T_da
        lin_cost_da_out = Δt_DA * λ_da[t] * eb_da_out[t]
        lin_cost_da_in = -Δt_DA * λ_da[t] * eb_da_in[t]
        #lin_cost_on_th = - Δt_DA * C_th_fix * on_th[t]
        PSI.add_to_objective_invariant_expression!(container, lin_cost_da_out)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_da_in)
        #PSI.add_to_objective_invariant_expression!(container, lin_cost_on_th)
    end

    # RT costs
    eb_rt_out = PSI.get_variable(container, energyRTBidOut(), HybridSystem)
    eb_rt_in = PSI.get_variable(container, energyRTBidIn(), HybridSystem)
    p_out = PSI.get_variable(container, HybridPowerOut(), HybridSystem)
    p_in = PSI.get_variable(container, HybridPowerIn(), HybridSystem)
    status = PSI.get_variable(container, HybridStatus(), HybridSystem)
    #p_th = PSI.get_variable(container, ThermalPower(), HybridSystem)
    p_re = PSI.get_variable(container, RenewablePower(), HybridSystem)
    p_ch = PSI.get_variable(container, BatteryCharge(), HybridSystem)
    p_ds = PSI.get_variable(container, BatteryDischarge(), HybridSystem)
    e_st = PSI.get_variable(container, BatteryStateOfCharge(), HybridSystem)
    status_st = PSI.get_variable(container, BatteryStatus(), HybridSystem)

    for t in T_rt
        lin_cost_rt_out = Δt_RT * λ_rt[t] * eb_rt_out[t]
        lin_cost_rt_in = -Δt_RT * λ_rt[t] * eb_rt_in[t]
        #lin_cost_p_th = - Δt_RT * C_th_var * p_th[t]
        lin_cost_p_ch = -Δt_RT * VOM * p_ch[t]
        lin_cost_p_ds = -Δt_RT * VOM * p_ds[t]
        PSI.add_to_objective_invariant_expression!(container, lin_cost_rt_out)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_rt_in)
        #PSI.add_to_objective_invariant_expression!(container, lin_cost_p_th)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_p_ch)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_p_ds)
    end
    JuMP.@objective(model, MOI.MAX_SENSE, container.objective_function.invariant_terms)

    ###############################
    ######## Constraints ##########
    ###############################

    # BidBalance
    constraint_eb_out =
        PSI.add_constraints_container!(container, BidBalanceOut(), HybridSystem, T_rt)
    constraint_eb_in =
        PSI.add_constraints_container!(container, BidBalanceIn(), HybridSystem, T_rt)

    constraint_status_bid_in =
        PSI.add_constraints_container!(container, StatusInOn(), HybridSystem, T_rt)

    constraint_status_bid_out =
        PSI.add_constraints_container!(container, StatusOutOn(), HybridSystem, T_rt)

    constraint_balance =
        PSI.add_constraints_container!(container, EnergyAssetBalance(), HybridSystem, T_rt)

    # Thermal not implemented yet
    #=
    constraint_thermal_on = PSI.add_constraints_container!(
        container,
        ThermalStatusOn(),
        HybridSystem,
        T_da,
    )

    constraint_thermal_off = PSI.add_constraints_container!(
        container,
        ThermalStatusOff(),
        HybridSystem,
        T_da,
    )
    =#
    constraint_battery_charging = PSI.add_constraints_container!(
        container,
        BatteryStatusChargeOn(),
        HybridSystem,
        T_rt,
    )

    constraint_battery_discharging = PSI.add_constraints_container!(
        container,
        BatteryStatusDischargeOn(),
        HybridSystem,
        T_rt,
    )

    constraint_battery_balance =
        PSI.add_constraints_container!(container, BatteryBalance(), HybridSystem, T_rt)

    constraint_cycling_charge =
        PSI.add_constraints_container!(container, CyclingCharge(), HybridSystem, 1)

    constraint_cycling_discharge =
        PSI.add_constraints_container!(container, CyclingDischarge(), HybridSystem, 1)

    for t in T_rt
        # Market Constraint Bids in/out
        constraint_eb_out[t] = JuMP.@constraint(model, eb_rt_out[t] == p_out[t])
        constraint_eb_in[t] = JuMP.@constraint(model, eb_rt_in[t] == p_in[t])
        # Status Bids
        constraint_status_bid_in[t] =
            JuMP.@constraint(model, (1.0 - status[t]) * P_max_pcc == p_in[t])
        constraint_status_bid_out[t] =
            JuMP.@constraint(model, status[t] * P_max_pcc .>= p_out[t])
        # Power Balance
        constraint_balance[t] = JuMP.@constraint(
            model,
            p_re[t] + p_ds[t] - p_ch[t] - P_ld[t] - p_out[t] + p_in[t] == 0.0
        )
        #= Thermal Status
        constraint_thermal_on[t] =  JuMP.@constraint(model, p_th[t] <= on_th[tmap[t]] * P_max_th)
        constraint_thermal_off[t] = JuMP.@constraint(model, p_th[t] >= on_th[tmap[t]] * P_min_th)
        =#
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
    return
end
