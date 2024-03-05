# HybridSystemsSimulations.jl

```@meta
CurrentModule = HybridSystemsSimulations
```

## Overview

HybridSystemsSimulations.jl supports different three major simulation configurations:

1. Centralized Dispatch: Simulation that assumes a centralized ISO operates the Hybrid System.
2. Single Asset Operation: Simulation of the merchant model bidding behavior given market products and renewable energy forecasts. This simulation assumes that the Hybrid System clears at the forecasted prices.
3. Market Participation: This simulation takes the market bids from the same model and clears the market for those bids. It enables an assessment of the effects of the bidding behavior in the market. Also, it can simulate the adjustments the hybrid system can take in its position, given the changes in the renewable energy forecast.

HybridSystemsSimulations.jl uses PowerSystems.jl and PowerSimulations.jl which can enable other
configurations and the models in this library are not limited to the cases described above.

* * *

HybridSystemsSimulations has been developed as part of the FlexPower Project at the U.S. Department of Energy's National Renewable Energy Laboratory ([NREL](https://www.nrel.gov/))
