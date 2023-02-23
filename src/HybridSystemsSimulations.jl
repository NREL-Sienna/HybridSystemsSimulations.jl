module HybridSystemsSimulations

using DocStringExtensions
import PowerSimulations
const PSI = PowerSimulations

@template (FUNCTIONS, METHODS) = """
                                 $(TYPEDSIGNATURES)
                                 $(DOCSTRING)
                                 """

end
