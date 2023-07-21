### Define Variables using PSI.VariableType
# Energy Bids
struct EnergyDABidOut <: PSI.VariableType end
struct EnergyDABidIn <: PSI.VariableType end
struct EnergyRTBidOut <: PSI.VariableType end
struct EnergyRTBidIn <: PSI.VariableType end

# Energy Asset Bids
struct EnergyThermalBid <: PSI.VariableType end
struct EnergyRenewableBid <: PSI.VariableType end
struct EnergyBatteryChargeBid <: PSI.VariableType end
struct EnergyBatteryDischargeBid <: PSI.VariableType end

# AS Total DA Bids
struct BidReserveVariableOut <: PSI.VariableType end
struct BidReserveVariableIn <: PSI.VariableType end

# Component Variables
abstract type HybridAssetVariableType <: PSI.VariableType end
struct ThermalPower <: HybridAssetVariableType end
struct RenewablePower <: HybridAssetVariableType end
struct BatteryCharge <: HybridAssetVariableType end
struct BatteryDischarge <: HybridAssetVariableType end
struct BatteryStatus <: HybridAssetVariableType end

# AS Variable for Hybrid
struct ReserveVariableOut <: PSI.VariableType end
struct ReserveVariableIn <: PSI.VariableType end
struct ReserveReservationVariable <: PSI.VariableType end

abstract type ComponentReserveVariableType <: PSI.VariableType end

struct ChargingReserveVariable <: ComponentReserveVariableType end
struct DischargingReserveVariable <: ComponentReserveVariableType end
struct ThermalReserveVariable <: ComponentReserveVariableType end
struct RenewableReserveVariable <: ComponentReserveVariableType end

# implement below
# convert_result_to_natural_units(::Type{<:VariableType}) = false
