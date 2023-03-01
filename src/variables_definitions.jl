using PowerSimulations
const PSI = PowerSimulations
### Define Variables using PSI.VariableType
# Energy Bids
struct energyDABidOut <: PSI.VariableType end
struct energyDABidIn <: PSI.VariableType end
struct energyRTBidOut <: PSI.VariableType end
struct energyRTBidIn <: PSI.VariableType end

# Energy Asset Bids
struct energyThermalBidOut <: PSI.VariableType end
struct energyThermalBidIn <: PSI.VariableType end
struct energyRenewableBidOut <: PSI.VariableType end
struct energyRenewableBidIn <: PSI.VariableType end
struct energyBatteryChargeBidOut <: PSI.VariableType end
struct energyBatteryChargeBidIn <: PSI.VariableType end
struct energyBatteryDischargeBidOut <: PSI.VariableType end
struct energyBatteryDischargeBidIn <: PSI.VariableType end

# AS Total Bids
struct regUpDABidOut <: PSI.VariableType end
struct regUpDABidIn <: PSI.VariableType end
struct regDownDABidOut <: PSI.VariableType end
struct regDownDABidIn <: PSI.VariableType end
struct regSpinDABidOut <: PSI.VariableType end
struct regSpinDABidIn <: PSI.VariableType end

# AS Thermal Bids
struct regUpThermalBidOut <: PSI.VariableType end
struct regUpThermalBidIn <: PSI.VariableType end
struct regDownThermalBidOut <: PSI.VariableType end
struct regDownThermalBidIn <: PSI.VariableType end
struct regSpinThermalBidOut <: PSI.VariableType end
struct regSpinThermalBidIn <: PSI.VariableType end

# AS Renewable Bids
struct regUpRenewableBidOut <: PSI.VariableType end
struct regUpRenewableBidIn <: PSI.VariableType end
struct regDownRenewableBidOut <: PSI.VariableType end
struct regDownRenewableBidIn <: PSI.VariableType end
struct regSpinRenewableBidOut <: PSI.VariableType end
struct regSpinRenewableBidIn <: PSI.VariableType end

# AS Battery Charge Bids
struct regUpBatteryChargeBidOut <: PSI.VariableType end
struct regUpBatteryChargeBidIn <: PSI.VariableType end
struct regDownBatteryChargeBidOut <: PSI.VariableType end
struct regDownBatterChargeyBidIn <: PSI.VariableType end
struct regSpinBatteryChargeBidOut <: PSI.VariableType end
struct regSpinBatteryChargeBidIn <: PSI.VariableType end

# AS Battery Discharge Bids
struct regUpBatteryDischargeBidOut <: PSI.VariableType end
struct regUpBatteryDischargeBidIn <: PSI.VariableType end
struct regDownBatteryDischargeBidOut <: PSI.VariableType end
struct regDownBatterDischargeyBidIn <: PSI.VariableType end
struct regSpinBatteryDischargeBidOut <: PSI.VariableType end
struct regSpinBatteryDischargeBidIn <: PSI.VariableType end

# Physical Variables
struct HybridPowerOut <: PSI.VariableType end
struct HybridPowerIn <: PSI.VariableType end
struct HybridStatus <: PSI.VariableType end

# Asset Variables
struct ThermalPower <: PSI.VariableType end
struct ThermalStatus <: PSI.VariableType end
struct RenewablePower <: PSI.VariableType end
struct BatteryCharge <: PSI.VariableType end
struct BatteryDischarge <: PSI.VariableType end
struct BatteryStateOfCharge <: PSI.VariableType end
struct BatteryStatus <: PSI.VariableType end
