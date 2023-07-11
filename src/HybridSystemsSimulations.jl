module HybridSystemsSimulations

# Device Formulations
export HybridEnergyOnlyDispatch
export HybridEnergyOnlyFixedDA
export HybridDispatchWithReserves

# Decision Models
export MerchantHybridEnergyOnly
export MerchantHybridCooptimized
export MerchantHybridEnergyCase
export MerchantHybridEnergyFixedDA

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

include("core/decision_models.jl")
include("core/formulations.jl")
include("core/parameters.jl")
include("core/variables.jl")
include("core/constraints.jl")
include("core/expressions.jl")
include("hybrid_system_decision_models.jl")
include("hybrid_system_device_models.jl")
include("hybrid_system_constructor.jl")

end
