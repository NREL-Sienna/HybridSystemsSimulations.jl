############## TimeSeries, HybridSystems ##########################

function PSI.get_default_time_series_names(
    ::Type{PSY.HybridSystem},
    ::Type{<:Union{PSI.FixedOutput, AbstractHybridFormulation}},
)
    return Dict{Type{<:PSI.TimeSeriesParameter}, String}(
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

PSI.get_multiplier_value(
    ::RenewablePowerTimeSeries,
    device::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_max_active_power(PSY.get_renewable_unit(device))

PSI.get_multiplier_value(
    ::ElectricLoadTimeSeries,
    device::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_max_active_power(PSY.get_electric_load(device))

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

PSY.get_active_power_limits(device::PSY.HybridSystem) =
    PSY.get_output_active_power_limits(device)

############## PSI.Reservation Variables, HybridSystem ####################

PSI.get_variable_binary(
    ::PSI.ReservationVariable,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = true

############### Asset Variables, HybridSystem #####################
PSI.get_default_on_variable(::PSY.HybridSystem) = PSI.OnVariable()

# Upper Bound
PSI.get_variable_upper_bound(
    ::Union{ThermalPower, EnergyThermalBid},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_active_power_limits(PSY.get_thermal_unit(d)).max

PSI.get_variable_upper_bound(
    ::Union{RenewablePower, EnergyRenewableBid},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_max_active_power(PSY.get_renewable_unit(d))

PSI.get_variable_upper_bound(
    ::Union{BatteryCharge, EnergyBatteryChargeBid},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_input_active_power_limits(PSY.get_storage(d)).max

PSI.get_variable_upper_bound(
    ::Union{BatteryDischarge, EnergyBatteryDischargeBid},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_output_active_power_limits(PSY.get_storage(d)).max

PSI.get_variable_upper_bound(
    ::PSI.EnergyVariable,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_state_of_charge_limits(PSY.get_storage(d)).max

PSI.get_variable_upper_bound(
    ::PSI.OnVariable,
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
    ::Union{ThermalPower, EnergyThermalBid},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0

PSI.get_variable_lower_bound(
    ::Union{RenewablePower, EnergyRenewableBid},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0

PSI.get_variable_lower_bound(
    ::Union{BatteryCharge, EnergyBatteryChargeBid},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0

PSI.get_variable_lower_bound(
    ::Union{BatteryDischarge, EnergyBatteryDischargeBid},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = 0.0

PSI.get_variable_lower_bound(
    ::PSI.EnergyVariable,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_state_of_charge_limits(PSY.get_storage(d)).min

PSI.get_variable_lower_bound(
    ::PSI.OnVariable,
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
    ::Union{ThermalPower, EnergyThermalBid},
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_binary(
    ::PSI.OnVariable,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = true
PSI.get_variable_binary(
    ::Union{RenewablePower, EnergyRenewableBid},
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_binary(
    ::Union{BatteryCharge, EnergyBatteryChargeBid},
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_binary(
    ::Union{BatteryDischarge, EnergyBatteryDischargeBid},
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_binary(
    ::PSI.EnergyVariable,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = false
PSI.get_variable_binary(
    ::BatteryStatus,
    ::Type{PSY.HybridSystem},
    ::AbstractHybridFormulation,
) = true

PSI.initial_condition_default(
    ::PSI.InitialEnergyLevel,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSY.get_initial_energy(PSY.get_storage(d))
PSI.initial_condition_variable(
    ::PSI.InitialEnergyLevel,
    d::PSY.HybridSystem,
    ::AbstractHybridFormulation,
) = PSI.EnergyVariable()

################### Reserve Variables ############################

PSI.get_expression_type_for_reserve(
    ::PSI.ActivePowerReserveVariable,
    ::Type{<:PSY.HybridSystem},
    ::Type{<:PSY.Reserve{PSY.ReserveUp}},
) = PSI.ReserveRangeExpressionUB
PSI.get_expression_type_for_reserve(
    ::PSI.ActivePowerReserveVariable,
    ::Type{<:PSY.HybridSystem},
    ::Type{<:PSY.Reserve{PSY.ReserveDown}},
) = PSI.ReserveRangeExpressionLB

PSI.get_variable_multiplier(
    ::Type{<:ComponentReserveVariableType},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 1.0
PSI.get_variable_multiplier(
    ::Type{<:ComponentReserveVariableType},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0
PSI.get_variable_multiplier(
    ::Type{ChargingReserveVariable},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 1.0
PSI.get_variable_multiplier(
    ::Type{ChargingReserveVariable},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0
PSI.get_variable_multiplier(
    ::Type{ThermalReserveVariable},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveUp},
) = 1.0
PSI.get_variable_multiplier(
    ::Type{ThermalReserveVariable},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve{PSY.ReserveDown},
) = 1.0

PSI.get_variable_multiplier(
    ::Type{ReserveVariableOut},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve,
) = 1.0
PSI.get_variable_multiplier(
    ::Type{ReserveVariableIn},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve,
) = 1.0

PSI.get_variable_multiplier(
    ::Type{BidReserveVariableOut},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve,
) = 1.0
PSI.get_variable_multiplier(
    ::Type{BidReserveVariableIn},
    d::PSY.HybridSystem,
    ::AbstractHybridFormulationWithReserves,
    ::PSY.Reserve,
) = 1.0

################### Parameters ############################

PSI.get_parameter_multiplier(
    ::PSI.FixValueParameter,
    ::PSY.HybridSystem,
    ::Union{HybridEnergyOnlyFixedDA, HybridEnergyOnlyDispatch},
) = 1.0

###################################################################
######################## Initial Conditions #######################
###################################################################

function PSI.initial_conditions!(
    container::PSI.OptimizationContainer,
    devices::Vector{D},
    formulation::AbstractHybridFormulation,
) where {D <: PSY.HybridSystem}
    PSI.add_initial_condition!(container, devices, formulation, PSI.InitialEnergyLevel())
    return
end