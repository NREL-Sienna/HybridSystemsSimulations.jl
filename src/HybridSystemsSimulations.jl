module HybridSystemsSimulations

# Device Formulations
export HybridEnergyOnlyDispatch
export HybridEnergyOnlyFixedDA
export HybridDispatchWithReserves

# Decision Models
export MerchantHybridEnergyCase
export MerchantHybridEnergyFixedDA
export MerchantHybridCooptimizerCase
export MerchantHybridBilevelCase

# Variables
export EnergyDABidOut
export EnergyDABidIn
export EnergyRTBidOut
export EnergyRTBidIn
export BidReserveVariableOut
export BidReserveVariableIn

# Constraints
export OptConditionRenewablePower
export OptConditionBatteryCharge
export OptConditionBatteryDischarge
export OptConditionEnergyVariable
export OptConditionThermalPower
export ComplementarySlacknessRenewableActivePowerLimitConstraintUb
export ComplementarySlacknessEnergyAssetBalanceUb
export ComplementarySlacknessEnergyAssetBalanceLb
export ComplementarySlacknessBatteryStatusDischargeOnUb
export ComplementarySlacknessBatteryStatusDischargeOnLb
export ComplementarySlacknessBatteryStatusChargeOnUb
export ComplementarySlacknessBatteryStatusChargeOnLb
export ComplementarySlacknessBatteryBalanceUb
export ComplementarySlacknessBatteryBalanceLb
export ComplentarySlacknessCyclingCharge
export ComplentarySlacknessCyclingDischarge
export ComplementarySlacknessEnergyLimitUb
export ComplementarySlacknessEnergyLimitLb
export ComplementarySlacknessThermalOnVariableOn
export ComplementarySlacknessThermalOnVariableOff
export StrongDualityCut

# Parameters
export DayAheadEnergyPrice
export RealTimeEnergyPrice
export AncillaryServicePrice
export ChargeCycleLimit
export DischargeCycleLimit

import MathOptInterface
import PowerSimulations
import PowerSystems
import JuMP
import Dates
import DataFrames
import DataStructures: OrderedDict

const MOI = MathOptInterface
const PSI = PowerSimulations
const PSY = PowerSystems
const PM = PSI.PM
const IS = PSI.IS

using DocStringExtensions
@template (FUNCTIONS, METHODS) = """
                                 $(TYPEDSIGNATURES)
                                 $(DOCSTRING)
                                 """

include("core/decision_models.jl")
include("core/formulations.jl")
include("core/parameters.jl")
include("core/variables.jl")
include("core/constraints.jl")
include("core/expressions.jl")
include("add_to_expression.jl")
include("hybrid_system_decision_models.jl")
include("hybrid_system_device_models.jl")
include("add_variables.jl")
include("add_parameters.jl")
include("add_constraints.jl")
include("objective_function.jl")
include("decision_models/only_energy_decision_model.jl")
include("decision_models/cooptimizer_decision_model.jl")
include("decision_models/bilevel_decision_model.jl")
include("hybrid_system_constructor.jl")

end
