# Load SIIP Packages
using PowerSimulations
using PowerSystems
using PowerSystemCaseBuilder
using InfrastructureSystems
using PowerNetworkMatrices
using HybridSystemsSimulations
using HydroPowerSimulations
using StorageSystemsSimulations
import OrderedCollections: OrderedDict
const PSY = PowerSystems
const PSI = PowerSimulations
const PSB = PowerSystemCaseBuilder
const HSS = HybridSystemsSimulations

# Load Optimization and Useful Packages
using Xpress
using JuMP
using Logging
using Dates
using CSV
using TimeSeries
using PlotlyJS
using DataFrames

result_folder = joinpath(
    @__DIR__,
    "../..",
    "merchant_sim_MerchantHybridCooptimizerCase_2020-07-10T00:00:00-5",
)

results = SimulationResults(result_folder; ignore_status=true)

results_merch_DA = get_decision_problem_results(results, "MerchantHybridCooptimizerCase_DA")



bid_rt = read_realized_variable(results_merch_DA, "EnergyRTBidOut__HybridSystem")
bid_da = read_variable(results_merch_DA, "EnergyDABidOut__HybridSystem")
