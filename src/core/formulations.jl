########################### Hybrid Generation Formulations ################################
abstract type AbstractHybridFormulation <: PSI.AbstractDeviceFormulation end
abstract type AbstractHybridFormulationWithReserves <: AbstractHybridFormulation end
struct HybridDispatchWithReserves <: AbstractHybridFormulationWithReserves end
struct HybridEnergyOnlyDispatch <: AbstractHybridFormulation end
struct HybridEnergyOnlyFixedDA <: AbstractHybridFormulation end
struct HybridWithReservesFixedDA <: AbstractHybridFormulation end

struct MerchantModelEnergyOnly <: AbstractHybridFormulation end
struct MerchantModelWithReserves <: AbstractHybridFormulationWithReserves end
