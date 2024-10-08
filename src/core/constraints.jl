### Define Constraints using PSI.ConstraintType ###

###################
### Upper Level ###
###################

## DA Bid Limits ##
struct DayAheadBidOutRangeLimit <: PSI.ConstraintType end
struct DayAheadBidInRangeLimit <: PSI.ConstraintType end

## RT Bid Limits ##
struct RealTimeBidOutRangeLimit <: PSI.ConstraintType end
struct RealTimeBidInRangeLimit <: PSI.ConstraintType end

## Energy Market Asset Balance ##
struct EnergyBidAssetBalance <: PSI.ConstraintType end

## AS Market Convergence ##
struct MarketOutConvergence <: PSI.ConstraintType end
struct MarketInConvergence <: PSI.ConstraintType end

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

## AS for Components
struct ReserveCoverageConstraint <: PSI.ConstraintType end
struct ReserveCoverageConstraintEndOfPeriod <: PSI.ConstraintType end
struct ChargingReservePowerLimit <: PSI.ConstraintType end
struct DischargingReservePowerLimit <: PSI.ConstraintType end
struct ThermalReserveLimit <: PSI.ConstraintType end
struct RenewableReserveLimit <: PSI.ConstraintType end

## Auxiliary for Output
struct ReserveBalance <: PSI.ConstraintType end
# Used for DeviceModels inside UC/ED to equate with the ActivePowerReserveVariable
struct HybridReserveAssignmentConstraint <: PSI.ConstraintType end

###################
### Lower Level ###
###################

struct EnergyAssetBalance <: PSI.ConstraintType end
struct ThermalOnVariableUb <: PSI.ConstraintType end
struct ThermalOnVariableLb <: PSI.ConstraintType end
struct BatteryStatusChargeOn <: PSI.ConstraintType end
struct BatteryStatusDischargeOn <: PSI.ConstraintType end
struct BatteryBalance <: PSI.ConstraintType end
struct CyclingCharge <: PSI.ConstraintType end
struct CyclingDischarge <: PSI.ConstraintType end
struct ChargeRegularizationConstraint <: PSI.ConstraintType end
struct DischargeRegularizationConstraint <: PSI.ConstraintType end
struct StateofChargeTargetConstraint <: PSI.ConstraintType end
struct RenewableActivePowerLimitConstraint <: PSI.ConstraintType end

###################
### Feedforwards ###
###################

struct FeedForwardCyclingChargeConstraint <: PSI.ConstraintType end
struct FeedForwardCyclingDischargeConstraint <: PSI.ConstraintType end

##############################################
### Dual Optimality Conditions Constraints ###
##############################################
# Names track the variable types in variables.jl
struct OptConditionThermalPower <: PSI.ConstraintType end
struct OptConditionRenewablePower <: PSI.ConstraintType end
struct OptConditionBatteryCharge <: PSI.ConstraintType end
struct OptConditionBatteryDischarge <: PSI.ConstraintType end
# EnergyVariable is defined in PSI
struct OptConditionEnergyVariable <: PSI.ConstraintType end

###############################################
##### Complementaty Slackness Constraints #####
###############################################
# Names track the constraint types and their Meta Ub and Lb
struct ComplementarySlacknessEnergyAssetBalanceUb <: PSI.ConstraintType end
struct ComplementarySlacknessEnergyAssetBalanceLb <: PSI.ConstraintType end
struct ComplementarySlacknessThermalOnVariableUb <: PSI.ConstraintType end
struct ComplementarySlacknessThermalOnVariableLb <: PSI.ConstraintType end
struct ComplementarySlacknessRenewableActivePowerLimitConstraintUb <: PSI.ConstraintType end
struct ComplementarySlacknessRenewableActivePowerLimitConstraintLb <: PSI.ConstraintType end
struct ComplementarySlacknessBatteryStatusDischargeOnUb <: PSI.ConstraintType end
struct ComplementarySlacknessBatteryStatusDischargeOnLb <: PSI.ConstraintType end
struct ComplementarySlacknessBatteryStatusChargeOnUb <: PSI.ConstraintType end
struct ComplementarySlacknessBatteryStatusChargeOnLb <: PSI.ConstraintType end
struct ComplementarySlacknessBatteryBalanceUb <: PSI.ConstraintType end
struct ComplementarySlacknessBatteryBalanceLb <: PSI.ConstraintType end
struct ComplentarySlacknessCyclingCharge <: PSI.ConstraintType end
struct ComplentarySlacknessCyclingDischarge <: PSI.ConstraintType end
struct ComplementarySlacknessEnergyLimitUb <: PSI.ConstraintType end
struct ComplementarySlacknessEnergyLimitLb <: PSI.ConstraintType end
struct StrongDualityCut <: PSI.ConstraintType end
