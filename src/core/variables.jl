### Define Variables using PSI.VariableType
# Energy Bids
struct EnergyDABidOut <: PSI.VariableType end
struct EnergyDABidIn <: PSI.VariableType end
struct EnergyRTBidOut <: PSI.VariableType end
struct EnergyRTBidIn <: PSI.VariableType end

# Energy Asset Bids
struct EnergyThermalBid <: PSI.VariableType end
struct EnergyRenewableBid <: PSI.VariableType end
struct EnergyBatteryChargeBid <: PSI.VariableType end
struct EnergyBatteryDischargeBid <: PSI.VariableType end

# AS Total DA Bids
struct BidReserveVariableOut <: PSI.VariableType end
struct BidReserveVariableIn <: PSI.VariableType end

# Component Variables
abstract type HybridAssetVariableType <: PSI.VariableType end
struct ThermalPower <: HybridAssetVariableType end
struct RenewablePower <: HybridAssetVariableType end
struct BatteryCharge <: HybridAssetVariableType end
struct BatteryDischarge <: HybridAssetVariableType end
struct BatteryStatus <: HybridAssetVariableType end

# AS Variable for Hybrid
struct ReserveVariableOut <: PSI.VariableType end
struct ReserveVariableIn <: PSI.VariableType end
struct ReserveReservationVariable <: PSI.VariableType end

abstract type ComponentReserveVariableType <: PSI.VariableType end

struct ChargingReserveVariable <: ComponentReserveVariableType end
struct DischargingReserveVariable <: ComponentReserveVariableType end
struct ThermalReserveVariable <: ComponentReserveVariableType end
struct RenewableReserveVariable <: ComponentReserveVariableType end

# Duals for Merchant Model
"""
Internal Merchant Model Devices EnergyAssetBalance Equation Upper Bound Dual
"""
struct λUb <: PSI.VariableType end
"""
Internal Merchant Model Devices EnergyAssetBalance Equation Lower Bound Dual
"""
struct λLb <: PSI.VariableType end
"""
ThermalGeneration Upper Bound Dual
"""
struct μThUb <: PSI.VariableType end
"""
ThermalGeneration Lower Bound Dual
"""
struct μThLb <: PSI.VariableType end
"""
RenewableGeneration Upper Bound Dual
"""
struct μReUb <: PSI.VariableType end
"""
RenewableGeneration Lower Bound Dual
"""
struct μReLb <: PSI.VariableType end
"""
Storage Charge Variable Upper Bound Dual
"""
struct μChUb <: PSI.VariableType end
"""
Storage Charge Variable Lower Bound Dual
"""
struct μChLb <: PSI.VariableType end
"""
Storage Discharge Variable Upper Bound Dual
"""
struct μDsUb <: PSI.VariableType end
"""
Storage Discharge Variable Lower Bound Dual
"""
struct μDsLb <: PSI.VariableType end
"""
Storage Energy Balance Equation Upper Bound Dual
"""
struct γStBalLb <: PSI.VariableType end
"""
Storage Energy Balance Equation Lower Bound Dual
"""
struct γStBalUb <: PSI.VariableType end
"""
Storage Energy Variable Upper Bound Dual
"""
struct νStUb <: PSI.VariableType end
"""
Storage Energy Variable Lower Bound Dual
"""
struct νStLb <: PSI.VariableType end
"""
Storage Discharging Cycling Limit Dual
"""
struct κStDs <: PSI.VariableType end
"""
Storage Charging Cycling Limit Dual
"""
struct κStCh <: PSI.VariableType end

###############################################
##### Complementaty Slackness Variables #####
###############################################
# Names track the constraint types and their Meta Ub and Lb
struct ComplementarySlackVarEnergyAssetBalanceUb <: PSI.VariableType end
struct ComplementarySlackVarEnergyAssetBalanceLb <: PSI.VariableType end
struct ComplementarySlackVarThermalOnVariableOn <: PSI.VariableType end
struct ComplementarySlackVarThermalOnVariableOff <: PSI.VariableType end
struct ComplementarySlackVarRenewableActivePowerLimitConstraintUb <: PSI.VariableType end
struct ComplementarySlackVarRenewableActivePowerLimitConstraintLb <: PSI.VariableType end
struct ComplementarySlackVarBatteryStatusDischargeOnUb <: PSI.VariableType end
struct ComplementarySlackVarBatteryStatusDischargeOnLb <: PSI.VariableType end
struct ComplementarySlackVarBatteryStatusChargeOnUb <: PSI.VariableType end
struct ComplementarySlackVarBatteryStatusChargeOnLb <: PSI.VariableType end
struct ComplementarySlackVarBatteryBalanceUb <: PSI.VariableType end
struct ComplementarySlackVarBatteryBalanceLb <: PSI.VariableType end
struct ComplementarySlackVarCyclingCharge <: PSI.VariableType end
struct ComplementarySlackVarCyclingDischarge <: PSI.VariableType end


# implement below
# convert_result_to_natural_units(::Type{<:VariableType}) = false
