using PowerSimulations
const PSI = PowerSimulations

### Define Constraints using PSI.ConstraintType ###

###################
### Upper Level ###
###################

## DA Bid Limits ##
struct BidOutDAUpperLimit <: PSI.ConstraintType end
struct BidInDAUpperLimit <: PSI.ConstraintType end
struct BidOutDALowerLimit <: PSI.ConstraintType end
struct BidInDALowerLimit <: PSI.ConstraintType end

## RT Bid Limits ##
struct BidOutRTUpperLimit <: PSI.ConstraintType end
struct BidInRTUpperLimit <: PSI.ConstraintType end
struct BidOutRTLowerLimit <: PSI.ConstraintType end
struct BidInRTLowerLimit <: PSI.ConstraintType end

## Battery AS State of Charge Coverage ##
struct regDownBatteryChargeCoverage <: PSI.ConstraintType end
struct regUpBatteryDischargeCoverage <: PSI.ConstraintType end
struct spinBatteryDischargeCoverage <: PSI.ConstraintType end

## Energy Market Asset Balance ##
struct energyBidAssetBalance <: PSI.ConstraintType end

## AS Market Asset Balance ##
struct regUpBidAssetBalance <: PSI.ConstraintType end
struct regDownBidAssetBalance <: PSI.ConstraintType end
struct spinBidAssetBalance <: PSI.ConstraintType end

## Internal Asset Bidding with AS ##
# Thermal
struct ThermalBidUp <: PSI.ConstraintType end
struct ThermalBidDown <: PSI.ConstraintType end
# Renewable
struct RenewableBidUp <: PSI.ConstraintType end
struct RenewableBidDown <: PSI.ConstraintType end
# Battery
struct BatteryChargeBidUp <: PSI.ConstraintType end
struct BatteryChargeBidDown <: PSI.ConstraintType end
struct BatteryDischargeBidUp <: PSI.ConstraintType end
struct BatteryDischargeBidDown <: PSI.ConstraintType end

##  Across Markets Balance ##
struct BidBalanceOut <: PSI.ConstraintType end
struct BidBalanceIn <: PSI.ConstraintType end
struct StatusOutOn <: PSI.ConstraintType end
struct StatusInOn <: PSI.ConstraintType end

###################
### Lower Level ###
###################

struct EnergyAssetBalance <: PSI.ConstraintType end
struct ThermalStatusOn <: PSI.ConstraintType end
struct ThermalStatusOff <: PSI.ConstraintType end
struct BatteryStatusChargeOn <: PSI.ConstraintType end
struct BatteryStatusDischargeOn <: PSI.ConstraintType end
struct BatteryBalance <: PSI.ConstraintType end
struct CyclingCharge <: PSI.ConstraintType end
struct CyclingDischarge <: PSI.ConstraintType end
