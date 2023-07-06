module HybridSystemsSimulations

# Device Formulations
export HybridEnergyOnlyDispatch
export HybridEnergyOnlyFixedDA
export HybridDispatchWithReserves

# Decision Models
export MerchantHybridEnergyCase
export MerchantHybridEnergyFixedDA
export MerchantHybridCooptimizerCase

# Variables
export EnergyDABidOut
export EnergyDABidIn
export EnergyRTBidOut
export EnergyRTBidIn

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

include("decision_models.jl")
include("formulations.jl")
include("parameters_definitions.jl")
include("variables_definitions.jl")
include("constraints_definitions.jl")
include("expressions_definitions.jl")
include("hybrid_system_decision_models.jl")
include("hybrid_system_device_models.jl")
include("hybrid_system_constructor.jl")

end
