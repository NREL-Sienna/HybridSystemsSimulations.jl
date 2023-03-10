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
struct RegUpDABidOut <: PSI.VariableType end
struct RegUpDABidIn <: PSI.VariableType end
struct SpinDABidOut <: PSI.VariableType end
struct SpinDABidIn <: PSI.VariableType end
struct RegDownDABidOut <: PSI.VariableType end
struct RegDownDABidIn <: PSI.VariableType end

# AS Total RT Bids
struct RegUpRTBidOut <: PSI.VariableType end
struct RegUpRTBidIn <: PSI.VariableType end
struct SpinRTBidOut <: PSI.VariableType end
struct SpinRTBidIn <: PSI.VariableType end
struct RegDownRTBidOut <: PSI.VariableType end
struct RegDownRTBidIn <: PSI.VariableType end

# AS Thermal Bids
struct RegUpThermalBid <: PSI.VariableType end
struct RegDownThermalBid <: PSI.VariableType end
struct SpinThermalBid <: PSI.VariableType end

# AS Renewable Bids
struct RegUpRenewableBid <: PSI.VariableType end
struct RegDownRenewableBid <: PSI.VariableType end
struct SpinRenewableBid <: PSI.VariableType end

# AS Battery Charge Bids
struct RegUpBatteryChargeBid <: PSI.VariableType end
struct RegDownBatteryChargeBid <: PSI.VariableType end
struct SpinBatteryChargeBid <: PSI.VariableType end

# AS Battery Discharge Bids
struct RegUpBatteryDischargeBid <: PSI.VariableType end
struct RegDownBatteryDischargeBid <: PSI.VariableType end
struct SpinBatteryDischargeBid <: PSI.VariableType end

# Component Variables
struct ThermalPower <: PSI.VariableType end
struct RenewablePower <: PSI.VariableType end
struct BatteryCharge <: PSI.VariableType end
struct BatteryDischarge <: PSI.VariableType end
struct BatteryStateOfCharge <: PSI.VariableType end
struct BatteryStatus <: PSI.VariableType end

# implement below
# convert_result_to_natural_units(::Type{<:VariableType}) = false
