using PowerSimulations
const PSI = PowerSimulations
### Define Variables using PSI.VariableType
# Bids
struct energyDABidOut <: PSI.VariableType end
struct energyDABidIn <: PSI.VariableType end
struct energyRTBidOut <: PSI.VariableType end
struct energyRTBidIn <: PSI.VariableType end

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

### Define Constraints using PSI.ConstraintType
struct BidBalanceOut <: PSI.ConstraintType end
struct BidBalanceIn <: PSI.ConstraintType end
struct StatusOutOn <: PSI.ConstraintType end
struct StatusInOn <: PSI.ConstraintType end
struct EnergyAssetBalance <: PSI.ConstraintType end
struct ThermalStatusOn <: PSI.ConstraintType end
struct ThermalStatusOff <: PSI.ConstraintType end
struct BatteryStatusChargeOn <: PSI.ConstraintType end
struct BatteryStatusDischargeOn <: PSI.ConstraintType end
struct BatteryBalance <: PSI.ConstraintType end
struct CyclingCharge <: PSI.ConstraintType end
struct CyclingDischarge <: PSI.ConstraintType end
