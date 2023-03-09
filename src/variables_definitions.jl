using PowerSimulations
const PSI = PowerSimulations
### Define Variables using PSI.VariableType
# Energy Bids
struct energyDABidOut <: PSI.VariableType end
struct energyDABidIn <: PSI.VariableType end
struct energyRTBidOut <: PSI.VariableType end
struct energyRTBidIn <: PSI.VariableType end

# Energy Asset Bids
struct energyThermalBid <: PSI.VariableType end
struct energyRenewableBid <: PSI.VariableType end
struct energyBatteryChargeBid <: PSI.VariableType end
struct energyBatteryDischargeBid <: PSI.VariableType end

# AS Total DA Bids
struct regUpDABidOut <: PSI.VariableType end
struct regUpDABidIn <: PSI.VariableType end
struct regSpinDABidOut <: PSI.VariableType end
struct regSpinDABidIn <: PSI.VariableType end
struct regDownDABidOut <: PSI.VariableType end
struct regDownDABidIn <: PSI.VariableType end

# AS Total RT Bids
struct regUpRTBidOut <: PSI.VariableType end
struct regUpRTBidIn <: PSI.VariableType end
struct regSpinRTBidOut <: PSI.VariableType end
struct regSpinRTBidIn <: PSI.VariableType end
struct regDownRTBidOut <: PSI.VariableType end
struct regDownRTBidIn <: PSI.VariableType end

# AS Thermal Bids
struct regUpThermalBid <: PSI.VariableType end
struct regDownThermalBid <: PSI.VariableType end
struct regSpinThermalBid <: PSI.VariableType end

# AS Renewable Bids
struct regUpRenewableBid <: PSI.VariableType end
struct regDownRenewableBid <: PSI.VariableType end
struct regSpinRenewableBid <: PSI.VariableType end

# AS Battery Charge Bids
struct regUpBatteryChargeBid <: PSI.VariableType end
struct regDownBatteryChargeBid <: PSI.VariableType end
struct regSpinBatteryChargeBid <: PSI.VariableType end

# AS Battery Discharge Bids
struct regUpBatteryDischargeBid <: PSI.VariableType end
struct regDownBatteryDischargeBid <: PSI.VariableType end
struct regSpinBatteryDischargeBid <: PSI.VariableType end

# Component Variables
struct ThermalPower <: PSI.VariableType end
struct RenewablePower <: PSI.VariableType end
struct BatteryCharge <: PSI.VariableType end
struct BatteryDischarge <: PSI.VariableType end
struct BatteryStateOfCharge <: PSI.VariableType end
struct BatteryStatus <: PSI.VariableType end
