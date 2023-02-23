########################### Hybrid Generation Formulations ################################
abstract type AbstractHybridFormulation <: AbstractDeviceFormulation end
abstract type AbstractStandardHybridFormulation <: AbstractHybridFormulation end
struct BasicHybridDispatch <: AbstractHybridFormulation end
struct StandardHybridDispatch <: AbstractStandardHybridFormulation end
struct HybridOptimizer <: PSI.DecisionModel end
