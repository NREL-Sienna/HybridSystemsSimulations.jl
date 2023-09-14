########################### Hybrid Generation Formulations ################################
abstract type AbstractHybridFormulation <: PSI.AbstractDeviceFormulation end
abstract type AbstractHybridFormulationWithReserves <: AbstractHybridFormulation end
struct HybridDispatchWithReserves <: AbstractHybridFormulationWithReserves end
struct HybridEnergyOnlyDispatch <: AbstractHybridFormulation end
struct HybridFixedDA <: AbstractHybridFormulation end

struct MerchantModelEnergyOnly <: AbstractHybridFormulation end
struct MerchantModelWithReserves <: AbstractHybridFormulationWithReserves end
