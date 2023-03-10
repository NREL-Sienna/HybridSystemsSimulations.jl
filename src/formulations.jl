########################### Hybrid Generation Formulations ################################
abstract type AbstractHybridFormulation end
struct HybridEnergyOnlyDispatch <: AbstractHybridFormulation end
struct HybridDispatch <: AbstractHybridFormulation end
