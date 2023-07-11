const CYCLES_PER_DAY = 1.37
const HOURS_IN_DAY = 24

struct RenewablePowerTimeSeries <: PSI.TimeSeriesParameter end
struct ElectricLoadTimeSeries <: PSI.TimeSeriesParameter end
struct DayAheadPrice <: PSI.ObjectiveFunctionParameter end
struct RealTimePrice <: PSI.ObjectiveFunctionParameter end
