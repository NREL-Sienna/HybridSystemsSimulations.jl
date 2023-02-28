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
