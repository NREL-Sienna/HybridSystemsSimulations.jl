########################### Hybrid Generation Formulations ################################
abstract type AbstractHybridFormulation <: PSI.AbstractDeviceFormulation end
struct HybridEnergyOnlyDispatch <: AbstractHybridFormulation end
#struct HybridEnergyOnlyDispatch <: AbstractHybridFormulation end
