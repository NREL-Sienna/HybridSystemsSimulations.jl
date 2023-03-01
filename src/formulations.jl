using PowerSimulations
const PSI = PowerSimulations
########################### Hybrid Generation Formulations ################################
abstract type AbstractHybridFormulation <: PSI.AbstractDeviceFormulation end
abstract type AbstractStandardHybridFormulation <: AbstractHybridFormulation end
struct BasicHybridDispatch <: AbstractHybridFormulation end
struct StandardHybridDispatch <: AbstractStandardHybridFormulation end
struct HybridOptimizer <: PSI.DecisionProblem end
struct HybridAncillariesCoOptimizer <: PSI.DecisionProblem end
