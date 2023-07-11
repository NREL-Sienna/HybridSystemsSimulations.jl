########################### Hybrid Generation Formulations ################################
abstract type AbstractHybridFormulation <: PSI.AbstractDeviceFormulation end
struct HybridDispatchWithReserves <: AbstractHybridFormulation end
struct HybridEnergyOnlyDispatch <: AbstractHybridFormulation end
struct HybridEnergyOnlyFixedDA <: AbstractHybridFormulation end

struct MerchantModelEnergyOnly <: AbstractHybridFormulation end
