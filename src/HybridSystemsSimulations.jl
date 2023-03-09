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
import PowerSystems
import JuMP

const MOI = MathOptInterface
const PSI = PowerSimulations
const PSY = PowerSystems

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
include("hybridsystems_device_models.jl")

end
