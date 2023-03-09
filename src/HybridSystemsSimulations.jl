module HybridSystemsSimulations

# Device Formulations
export HybridEnergyOnlyDispatch
export HybridDispatch

# Decision Models
export MerchantHybridEnergyOnly

# Variables
export EnergyDABidOut
export EnergyDABidIn

import MathOptInterface
import PowerSimulations
import JuMP


const PSI = PowerSimulations
const MOI = MathOptInterface

using DocStringExtensions
@template (FUNCTIONS, METHODS) = """
                                 $(TYPEDSIGNATURES)
                                 $(DOCSTRING)
                                 """

include("decision_models.jl")
include("formulations.jl")
include("variables_definitions.jl")
include("constraints_definitions.jl")
include("hybrid_decision_models.jl")
include("Hybrid_generation.jl")

end
