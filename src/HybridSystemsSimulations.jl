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

# Parameters
export DayAheadEnergyPrice
export RealTimeEnergyPrice
export AncillaryServicePrice

import MathOptInterface
import PowerSimulations
import PowerSystems
import JuMP
import Dates

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
include("hybrid_system_constructor.jl")

end
