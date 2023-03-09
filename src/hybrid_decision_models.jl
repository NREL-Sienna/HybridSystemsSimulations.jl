function add_variable!(
    decision_model::DecisionModel{U},
    type::T,
    time_range,
    lb,
    ub::Float64,
) where {T <: PSI.VariableType, U <: HybridDecisionProblem}
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
    decision_model::DecisionModel{U},
    type::T,
    time_range,
    lb,
    ub::Vector{Float64},
) where {T <: PSI.VariableType, U <: HybridDecisionProblem}
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
    decision_model::DecisionModel{U},
    type::T,
    time_range,
) where {T <: PSI.VariableType, U <: HybridDecisionProblem}
    name = string(type)[1:(end - 2)]
    container = PSI.get_optimization_container(decision_model)
    model = PSI.get_jump_model(decision_model)
    var = PSI.add_variable_container!(container, type, HybridSystem, time_range)
    for t in time_range
        var[t] = JuMP.@variable(model, base_name = "$(name)_$(t)", binary = true)
    end
    return
end

function PSI.build_impl!(decision_model::DecisionModel{MerchantHybridEnergyOnly})
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
    add_variable!(decision_model, EnergyDABidOut(), T_da, 0.0, P_max_pcc)
    add_variable!(decision_model, EnergyDABidIn(), T_da, 0.0, P_max_pcc)
    add_variable!(decision_model, energyRTBidOut(), T_rt, 0.0, P_max_pcc)
    add_variable!(decision_model, energyRTBidIn(), T_rt, 0.0, P_max_pcc)

    # Add PCC Variables
    add_variable!(decision_model, PSI.ActivePowerOutVariable(), T_rt, 0.0, P_max_pcc)
    add_variable!(decision_model, PSI.ActivePowerInVariable(), T_rt, 0.0, P_max_pcc)
    add_binary_variable!(decision_model, ReservationVariable(), T_rt)

    # Add Thermal Vars: No Thermal For now
    add_variable!(decision_model, ThermalPower(), T_rt, 0.0, P_max_th)
    add_binary_variable!(decision_model, OnVariable(), T_da)

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
    eb_da_out = PSI.get_variable(container, EnergyDABidOut(), HybridSystem)
    eb_da_in = PSI.get_variable(container, EnergyDABidIn(), HybridSystem)
    on_th = PSI.get_variable(container, OnVariable(), HybridSystem)

    for t in T_da
        lin_cost_da_out = Δt_DA * λ_da[t] * eb_da_out[t]
        lin_cost_da_in = -Δt_DA * λ_da[t] * eb_da_in[t]
        lin_cost_on_th = -Δt_DA * C_th_fix * on_th[t]
        PSI.add_to_objective_invariant_expression!(container, lin_cost_da_out)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_da_in)
        PSI.add_to_objective_invariant_expression!(container, lin_cost_on_th)
    end

    # RT costs
    eb_rt_out = PSI.get_variable(container, energyRTBidOut(), HybridSystem)
    eb_rt_in = PSI.get_variable(container, energyRTBidIn(), HybridSystem)
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), HybridSystem)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), HybridSystem)
    status = PSI.get_variable(container, ReservationVariable(), HybridSystem)
    p_th = PSI.get_variable(container, ThermalPower(), HybridSystem)
    p_re = PSI.get_variable(container, RenewablePower(), HybridSystem)
    p_ch = PSI.get_variable(container, BatteryCharge(), HybridSystem)
    p_ds = PSI.get_variable(container, BatteryDischarge(), HybridSystem)
    e_st = PSI.get_variable(container, BatteryStateOfCharge(), HybridSystem)
    status_st = PSI.get_variable(container, BatteryStatus(), HybridSystem)

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
        PSI.add_constraints_container!(container, BidBalanceOut(), HybridSystem, T_rt)
    constraint_eb_in =
        PSI.add_constraints_container!(container, BidBalanceIn(), HybridSystem, T_rt)

    constraint_status_bid_in =
        PSI.add_constraints_container!(container, StatusInOn(), HybridSystem, T_rt)

    constraint_status_bid_out =
        PSI.add_constraints_container!(container, StatusOutOn(), HybridSystem, T_rt)

    constraint_balance =
        PSI.add_constraints_container!(container, EnergyAssetBalance(), HybridSystem, T_rt)

    # Thermal
    constraint_thermal_on =
        PSI.add_constraints_container!(container, OnVariableOn(), HybridSystem, T_rt)

    constraint_thermal_off =
        PSI.add_constraints_container!(container, OnVariableOff(), HybridSystem, T_rt)
    # Battery Charging
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

function PSI.build_impl!(decision_model::DecisionModel{MerchantHybridCooptimized})
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
    add_variable!(decision_model, energyRTBidOut(), T_rt, 0.0, P_max_pcc) #eb_rt_out
    add_variable!(decision_model, energyRTBidIn(), T_rt, 0.0, P_max_pcc) #eb_rt_in

    # Internal Energy Asset Bid variables
    add_variable!(decision_model, energyThermalBid(), T_rt, 0.0, P_max_th) #eb_rt_th
    add_variable!(decision_model, energyRenewableBid(), T_rt, 0.0, P_re_star) #eb_rt_re
    add_variable!(decision_model, energyBatteryChargeBid(), T_rt, 0.0, P_ch_max) #eb_rt_ch
    add_variable!(decision_model, energyBatteryDischargeBid(), T_rt, 0.0, P_ds_max) #eb_rt_ds

    # AS Total DA Bids
    add_variable!(decision_model, regUpDABidOut(), T_da, 0.0, P_max_pcc) #sb_ru_da_out
    add_variable!(decision_model, regUpDABidIn(), T_da, 0.0, P_max_pcc) #sb_ru_da_in
    add_variable!(decision_model, regSpinDABidOut(), T_da, 0.0, P_max_pcc) #sb_spin_da_out
    add_variable!(decision_model, regSpinDABidIn(), T_da, 0.0, P_max_pcc) #sb_spin_da_in
    add_variable!(decision_model, regDownDABidOut(), T_da, 0.0, P_max_pcc) #sb_rd_da_out
    add_variable!(decision_model, regDownDABidIn(), T_da, 0.0, P_max_pcc) #sb_rd_da_in

    # AS Total RT Bids
    add_variable!(decision_model, regUpRTBidOut(), T_rt, 0.0, P_max_pcc) #sb_ru_rt_out
    add_variable!(decision_model, regUpRTBidIn(), T_rt, 0.0, P_max_pcc) #sb_ru_rt_in
    add_variable!(decision_model, regSpinRTBidOut(), T_rt, 0.0, P_max_pcc) #sb_spin_rt_out
    add_variable!(decision_model, regSpinRTBidIn(), T_rt, 0.0, P_max_pcc) #sb_spin_rt_in
    add_variable!(decision_model, regDownRTBidOut(), T_rt, 0.0, P_max_pcc) #sb_rd_rt_out
    add_variable!(decision_model, regDownRTBidIn(), T_rt, 0.0, P_max_pcc) #sb_rd_rt_in

    # AS Thermal RT Internal Bids
    add_variable!(decision_model, regUpThermalBid(), T_rt, 0.0, P_max_th) #sb_ru_th
    add_variable!(decision_model, regSpinThermalBid(), T_rt, 0.0, P_max_th) #sb_spin_th
    add_variable!(decision_model, regDownThermalBid(), T_rt, 0.0, P_max_th) #sb_rd_th

    # AS Renewable RT Internal Bids
    add_variable!(decision_model, regUpRenewableBid(), T_rt, 0.0, P_re_star) #sb_ru_re
    add_variable!(decision_model, regSpinRenewableBid(), T_rt, 0.0, P_re_star) #sb_spin_re
    add_variable!(decision_model, regDownRenewableBid(), T_rt, 0.0, P_re_star) #sb_rd_re

    # AS Battery Charge RT Internal Bids
    add_variable!(decision_model, regUpBatteryChargeBid(), T_rt, 0.0, P_ch_max) #sb_ru_ch
    add_variable!(decision_model, regSpinBatteryChargeBid(), T_rt, 0.0, P_ch_max) #sb_spin_ch
    add_variable!(decision_model, regDownBatteryChargeBid(), T_rt, 0.0, P_ch_max) #sb_rd_ch

    # AS Battery Charge RT Internal Bids
    add_variable!(decision_model, regUpBatteryDischargeBid(), T_rt, 0.0, P_ds_max) #sb_ru_ds
    add_variable!(decision_model, regSpinBatteryDischargeBid(), T_rt, 0.0, P_ds_max) #sb_spin_ds
    add_variable!(decision_model, regDownBatteryDischargeBid(), T_rt, 0.0, P_ds_max) #sb_rd_ds

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
    add_variable!(decision_model, BatteryStateOfCharge(), T_rt, E_min, E_max)
    add_binary_variable!(decision_model, BatteryStatus(), T_rt)

    ###############################
    ####### Obj. Function #########
    ###############################

    # DA costs
    eb_da_out = PSI.get_variable(container, EnergyDABidOut(), HybridSystem)
    eb_da_in = PSI.get_variable(container, EnergyDABidIn(), HybridSystem)
    on_th = PSI.get_variable(container, OnVariable(), HybridSystem)
    sb_ru_da_out = PSI.get_variable(container, regUpDABidOut(), HybridSystem)
    sb_ru_da_in = PSI.get_variable(container, regUpDABidIn(), HybridSystem)
    sb_spin_da_out = PSI.get_variable(container, regSpinDABidOut(), HybridSystem)
    sb_spin_da_in = PSI.get_variable(container, regSpinDABidIn(), HybridSystem)
    sb_rd_da_out = PSI.get_variable(container, regDownDABidOut(), HybridSystem)
    sb_rd_da_in = PSI.get_variable(container, regDownDABidIn(), HybridSystem)

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
    eb_rt_out = PSI.get_variable(container, energyRTBidOut(), HybridSystem)
    eb_rt_in = PSI.get_variable(container, energyRTBidIn(), HybridSystem)
    p_out = PSI.get_variable(container, PSI.ActivePowerOutVariable(), HybridSystem)
    p_in = PSI.get_variable(container, PSI.ActivePowerInVariable(), HybridSystem)
    status = PSI.get_variable(container, ReservationVariable(), HybridSystem)
    p_th = PSI.get_variable(container, ThermalPower(), HybridSystem)
    p_re = PSI.get_variable(container, RenewablePower(), HybridSystem)
    p_ch = PSI.get_variable(container, BatteryCharge(), HybridSystem)
    p_ds = PSI.get_variable(container, BatteryDischarge(), HybridSystem)
    e_st = PSI.get_variable(container, BatteryStateOfCharge(), HybridSystem)
    status_st = PSI.get_variable(container, BatteryStatus(), HybridSystem)

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
    sb_ru_rt_out = PSI.get_variable(container, regUpRTBidOut(), HybridSystem)
    sb_ru_rt_in = PSI.get_variable(container, regUpRTBidIn(), HybridSystem)
    sb_spin_rt_out = PSI.get_variable(container, regSpinRTBidOut(), HybridSystem)
    sb_spin_rt_in = PSI.get_variable(container, regSpinRTBidIn(), HybridSystem)
    sb_rd_rt_out = PSI.get_variable(container, regDownRTBidOut(), HybridSystem)
    sb_rd_rt_in = PSI.get_variable(container, regDownRTBidIn(), HybridSystem)
    # Internal Ancillary Services Bid Thermal
    sb_ru_th = PSI.get_variable(container, regUpThermalBid(), HybridSystem)
    sb_spin_th = PSI.get_variable(container, regSpinThermalBid(), HybridSystem)
    sb_rd_th = PSI.get_variable(container, regDownThermalBid(), HybridSystem)
    # Internal Ancillary Services Bid Renewable
    sb_ru_re = PSI.get_variable(container, regUpRenewableBid(), HybridSystem)
    sb_spin_re = PSI.get_variable(container, regSpinRenewableBid(), HybridSystem)
    sb_rd_re = PSI.get_variable(container, regDownRenewableBid(), HybridSystem)
    # Internal Ancillary Services Bid Charge Battery
    sb_ru_ch = PSI.get_variable(container, regUpBatteryChargeBid(), HybridSystem)
    sb_spin_ch = PSI.get_variable(container, regSpinBatteryChargeBid(), HybridSystem)
    sb_rd_ch = PSI.get_variable(container, regDownBatteryChargeBid(), HybridSystem)
    # Internal Ancillary Services Bid Discharge Battery
    sb_ru_ds = PSI.get_variable(container, regUpBatteryDischargeBid(), HybridSystem)
    sb_spin_ds = PSI.get_variable(container, regSpinBatteryDischargeBid(), HybridSystem)
    sb_rd_ds = PSI.get_variable(container, regDownBatteryDischargeBid(), HybridSystem)
    # RT Internal Asset Energy Bid
    eb_rt_th = PSI.get_variable(container, energyThermalBid(), HybridSystem)
    eb_rt_re = PSI.get_variable(container, energyRenewableBid(), HybridSystem)
    eb_rt_ch = PSI.get_variable(container, energyBatteryChargeBid(), HybridSystem)
    eb_rt_ds = PSI.get_variable(container, energyBatteryDischargeBid(), HybridSystem)

    ###################
    ### Upper Level ###
    ###################

    # Bid PCC Limits DA
    constraint_da_bid_up_out =
        PSI.add_constraints_container!(container, BidOutDAUpperLimit(), HybridSystem, T_da)
    constraint_da_bid_up_in =
        PSI.add_constraints_container!(container, BidInDAUpperLimit(), HybridSystem, T_da)
    constraint_da_bid_low_out =
        PSI.add_constraints_container!(container, BidOutDALowerLimit(), HybridSystem, T_da)
    constraint_da_bid_low_in =
        PSI.add_constraints_container!(container, BidInDALowerLimit(), HybridSystem, T_da)

    # Bid PCC Limits RT
    constraint_rt_bid_up_out =
        PSI.add_constraints_container!(container, BidOutRTUpperLimit(), HybridSystem, T_rt)
    constraint_rt_bid_low_out =
        PSI.add_constraints_container!(container, BidOutRTLowerLimit(), HybridSystem, T_rt)
    constraint_rt_bid_up_in =
        PSI.add_constraints_container!(container, BidInRTUpperLimit(), HybridSystem, T_rt)
    constraint_rt_bid_low_in =
        PSI.add_constraints_container!(container, BidInRTLowerLimit(), HybridSystem, T_rt)

    # Battery AS Coverage
    constraint_rd_charge_coverage = PSI.add_constraints_container!(
        container,
        regDownBatteryChargeCoverage(),
        HybridSystem,
        T_rt,
    )
    constraint_ru_discharge_coverage = PSI.add_constraints_container!(
        container,
        regUpBatteryDischargeCoverage(),
        HybridSystem,
        T_rt,
    )
    constraint_spin_discharge_coverage = PSI.add_constraints_container!(
        container,
        spinBatteryDischargeCoverage(),
        HybridSystem,
        T_rt,
    )

    # Energy Bid Asset Balance
    constraint_energy_bid_asset_balance = PSI.add_constraints_container!(
        container,
        energyBidAssetBalance(),
        HybridSystem,
        T_rt,
    )

    # Ancillary Services Market Convergence
    constraint_regup_bid_convergence = PSI.add_constraints_container!(
        container,
        regUpBidMarketConvergence(),
        HybridSystem,
        T_rt,
    )
    constraint_regdown_bid_convergence = PSI.add_constraints_container!(
        container,
        regDownBidMarketConvergence(),
        HybridSystem,
        T_rt,
    )
    constraint_spin_bid_convergence = PSI.add_constraints_container!(
        container,
        spinBidMarketConvergence(),
        HybridSystem,
        T_rt,
    )

    # Ancillary Services Bid Balance
    constraint_regup_bid_balance = PSI.add_constraints_container!(
        container,
        regUpBidAssetBalance(),
        HybridSystem,
        T_rt,
    )
    constraint_regdown_bid_balance = PSI.add_constraints_container!(
        container,
        regDownBidAssetBalance(),
        HybridSystem,
        T_rt,
    )
    constraint_spin_bid_balance =
        PSI.add_constraints_container!(container, spinBidAssetBalance(), HybridSystem, T_rt)

    # Thermal Bid Limits
    constraint_bid_up_thermal =
        PSI.add_constraints_container!(container, ThermalBidUp(), HybridSystem, T_rt)
    constraint_bid_down_thermal =
        PSI.add_constraints_container!(container, ThermalBidDown(), HybridSystem, T_rt)

    # Renewable Bid Limits
    constraint_bid_up_renewable =
        PSI.add_constraints_container!(container, RenewableBidUp(), HybridSystem, T_rt)
    constraint_bid_down_renewable =
        PSI.add_constraints_container!(container, RenewableBidDown(), HybridSystem, T_rt)

    # Battery Bid Limits
    constraint_bid_up_charge =
        PSI.add_constraints_container!(container, BatteryChargeBidUp(), HybridSystem, T_rt)
    constraint_bid_down_charge = PSI.add_constraints_container!(
        container,
        BatteryChargeBidDown(),
        HybridSystem,
        T_rt,
    )
    constraint_bid_up_discharge = PSI.add_constraints_container!(
        container,
        BatteryDischargeBidUp(),
        HybridSystem,
        T_rt,
    )
    constraint_bid_down_discharge = PSI.add_constraints_container!(
        container,
        BatteryDischargeBidDown(),
        HybridSystem,
        T_rt,
    )

    # Across Market Balance
    constraint_eb_out =
        PSI.add_constraints_container!(container, BidBalanceOut(), HybridSystem, T_rt)
    constraint_eb_in =
        PSI.add_constraints_container!(container, BidBalanceIn(), HybridSystem, T_rt)
    constraint_status_bid_in =
        PSI.add_constraints_container!(container, StatusInOn(), HybridSystem, T_rt)
    constraint_status_bid_out =
        PSI.add_constraints_container!(container, StatusOutOn(), HybridSystem, T_rt)

    ###################
    ### Lower Level ###
    ###################

    # Asset Balance
    constraint_balance =
        PSI.add_constraints_container!(container, EnergyAssetBalance(), HybridSystem, T_rt)

    # Thermal
    constraint_thermal_on =
        PSI.add_constraints_container!(container, OnVariableOn(), HybridSystem, T_rt)
    constraint_thermal_off =
        PSI.add_constraints_container!(container, OnVariableOff(), HybridSystem, T_rt)

    # Battery
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
            p_re[t] + p_ds[t] - p_ch[t] - P_ld[t] - p_out[t] + p_in[t] == 0.0
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
    PSI.serialize_metadata!(container, pwd())
    return
end
