using PowerSimulations
const PSI = PowerSimulations
########################### Hybrid Generation Formulations ################################
abstract type AbstractHybridFormulation <: PSI.AbstractDeviceFormulation end
abstract type AbstractStandardHybridFormulation <: AbstractHybridFormulation end
struct BasicHybridDispatch <: AbstractHybridFormulation end
struct StandardHybridDispatch <: AbstractStandardHybridFormulation end
abstract type HybridDecisionProblem <: PSI.DecisionProblem end
struct HybridOptimizer <: HybridDecisionProblem end
struct HybridCoOptimizer <: HybridDecisionProblem end
