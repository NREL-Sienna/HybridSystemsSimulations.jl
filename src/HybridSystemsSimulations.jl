module HybridSystemsSimulations

using DocStringExtensions
import PowerSimulations
import MathOptInterface
import PowerSimulations
const PSI = PowerSimulations
const MOI = MathOptInterface
const PSI = PowerSimulations

@template (FUNCTIONS, METHODS) = """
                                 $(TYPEDSIGNATURES)
                                 $(DOCSTRING)
                                 """

end

include("decision_models.jl")
include("formulations.jl")
include("variables_definitions.jl")
