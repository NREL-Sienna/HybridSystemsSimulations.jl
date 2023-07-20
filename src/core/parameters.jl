const CYCLES_PER_DAY = 1.37
const HOURS_IN_DAY = 24
const SERVE_FRACTION = 0.25

struct RenewablePowerTimeSeries <: PSI.TimeSeriesParameter end
struct ElectricLoadTimeSeries <: PSI.TimeSeriesParameter end
struct DayAheadEnergyPrice <: PSI.ObjectiveFunctionParameter end
struct RealTimeEnergyPrice <: PSI.ObjectiveFunctionParameter end
struct AncillaryServicePrice <: PSI.ObjectiveFunctionParameter end
