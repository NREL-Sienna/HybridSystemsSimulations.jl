module HybridSystemsSimulations

# Device Formulations
export HybridEnergyOnlyDispatch

# Decision Models
export MerchantHybridEnergyOnly
export MerchantHybridCooptimized

# Variables
export EnergyDABidOut
export EnergyDABidIn

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
const PNM = PSI.PNM

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
include("hybrid_system_decision_models.jl")
include("hybrid_system_device_models.jl")
include("hybrid_system_constructor.jl")

end
