const CYCLES_PER_DAY = 1.37
const HOURS_IN_DAY = 24

struct RenewablePowerTimeSeries <: PSI.TimeSeriesParameter end
struct ElectricLoadTimeSeries <: PSI.TimeSeriesParameter end
struct DayAheadEnergyPrice <: PSI.ObjectiveFunctionParameter end
struct RealTimeEnergyPrice <: PSI.ObjectiveFunctionParameter end
struct AncillaryServicePrice <: PSI.ObjectiveFunctionParameter end

PSI.should_write_resulting_value(::Type{DayAheadEnergyPrice}) = true
PSI.should_write_resulting_value(::Type{RealTimeEnergyPrice}) = true
