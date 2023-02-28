using PowerSimulations
const PSI = PowerSimulations

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
