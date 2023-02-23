module HybridSystemsSimulations

using DocStringExtensions
import PowerSimulations
import MathOptInterface
const PSI = PowerSimulations
const MOI = MathOptInterface

@template (FUNCTIONS, METHODS) = """
                                 $(TYPEDSIGNATURES)
                                 $(DOCSTRING)
                                 """

end
