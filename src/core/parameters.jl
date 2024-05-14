const CYCLES_PER_DAY = 1.37
const HOURS_IN_DAY = 24
const REG_COST = 0.001

struct RenewablePowerTimeSeries <: PSI.TimeSeriesParameter end
struct ElectricLoadTimeSeries <: PSI.TimeSeriesParameter end

struct DayAheadEnergyPrice <: PSI.ObjectiveFunctionParameter end
struct RealTimeEnergyPrice <: PSI.ObjectiveFunctionParameter end
struct AncillaryServicePrice <: PSI.ObjectiveFunctionParameter end

struct EnergyTargetParameter <: PSI.VariableValueParameter end
struct CyclingChargeLimitParameter <: PSI.VariableValueParameter end
struct CyclingDischargeLimitParameter <: PSI.VariableValueParameter end

PSI.should_write_resulting_value(::Type{DayAheadEnergyPrice}) = true
PSI.should_write_resulting_value(::Type{RealTimeEnergyPrice}) = true

# convert_result_to_natural_units(::Type{EnergyTargetParameter}) = true
