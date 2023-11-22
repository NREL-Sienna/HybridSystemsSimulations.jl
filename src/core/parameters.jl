const CYCLES_PER_DAY = 1.37
const HOURS_IN_DAY = 24
const RESERVE_SLACK_COST = 3000.0

struct RenewablePowerTimeSeries <: PSI.TimeSeriesParameter end
struct ElectricLoadTimeSeries <: PSI.TimeSeriesParameter end

struct DayAheadEnergyPrice <: PSI.ObjectiveFunctionParameter end
struct RealTimeEnergyPrice <: PSI.ObjectiveFunctionParameter end
struct AncillaryServicePrice <: PSI.ObjectiveFunctionParameter end

struct ChargeCycleLimit <: PSI.RightHandSideParameter end
struct DischargeCycleLimit <: PSI.RightHandSideParameter end

struct EnergyTargetParameter <: PSI.VariableValueParameter end

PSI.should_write_resulting_value(::Type{DayAheadEnergyPrice}) = true
PSI.should_write_resulting_value(::Type{RealTimeEnergyPrice}) = true

# convert_result_to_natural_units(::Type{EnergyTargetParameter}) = true
