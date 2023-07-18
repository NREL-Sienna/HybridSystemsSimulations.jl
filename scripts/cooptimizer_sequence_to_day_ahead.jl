using Pkg
Pkg.activate("test")
Pkg.instantiate()

using Revise

# Load SIIP Packages

using PowerSimulations
using PowerSystems
using PowerSystemCaseBuilder
using InfrastructureSystems
using PowerNetworkMatrices
using HybridSystemsSimulations
import OrderedCollections: OrderedDict
using JuMP
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

###############################
######## Load Scripts #########
###############################
include("get_templates.jl")
include("modify_systems.jl")
include("price_generation_utils.jl")
include("build_simulation_cases_reserves.jl")
include("utils.jl")

## Get Systems
# Let's do three days of 24 hours each for Day Ahead given that we have prices for three days
horizon_merchant_rt = 288
horizon_merchant_da = 24
sys_rts_merchant = PSB.build_RTS_GMLC_RT_sys(
    raw_data=PSB.RTS_DIR,
    horizon=horizon_merchant_rt,
    interval=Hour(24),
)
sys_rts_da = PSB.build_RTS_GMLC_DA_sys(raw_data=PSB.RTS_DIR, horizon=24)

#sys_rts_rt = PSB.build_RTS_GMLC_RT_sys(raw_data=PSB.RTS_DIR, horizon=864, interval=Minute(5))

# There is no Wind + Thermal in a Single Bus.
# We will try to pick the Wind in 317 bus Chuhsi
# It does not have thermal and load, so we will pick the adjacent bus 318: Clark
for s in [sys_rts_da, sys_rts_merchant]
    bus_to_add = "Chuhsi" # "Barton"
    modify_ren_curtailment_cost!(s)
    add_hybrid_to_chuhsi_bus!(s)
end

sys = sys_rts_merchant
sys.internal.ext = Dict{String, DataFrame}()
dic = PSY.get_ext(sys)

# Add prices to ext. Only three days.
bus_name = "chuhsi"
dic["λ_da_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic["λ_Reg_Up"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_RegUp_prices.csv", DataFrame)
dic["λ_Reg_Down"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_RegDown_prices.csv", DataFrame)
dic["λ_Spin_Up_R3"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_Spin_prices.csv", DataFrame)
dic["horizon_RT"] = horizon_merchant_rt
dic["horizon_DA"] = horizon_merchant_da

hy_sys = first(get_components(HybridSystem, sys))
services = get_components(VariableReserve, sys)
for service in services
    serv_name = get_name(service)
    if contains(serv_name, "Spin_Up_R1") |
       contains(serv_name, "Spin_Up_R2") |
       contains(serv_name, "Flex")
        continue
    else
        add_service!(hy_sys, service, sys)
    end
end
PSY.set_ext!(hy_sys, deepcopy(dic))

# Set decision model for Optimizer
decision_optimizer_DA = DecisionModel(
    MerchantHybridCooptimizerCase,
    ProblemTemplate(CopperPlatePowerModel),
    sys,
    optimizer=Xpress.Optimizer,
    calculate_conflict=true,
    store_variable_names=true;
    name="MerchantHybridCooptimizerCase_DA",
)

build!(decision_optimizer_DA; output_dir=pwd())

cons = decision_optimizer_DA.internal.container.constraints
vars = decision_optimizer_DA.internal.container.variables
params = decision_optimizer_DA.internal.container.parameters
exprs = decision_optimizer_DA.internal.container.expressions

cons[PSI.ConstraintKey{HSS.DayAheadBidInRangeLimit, HybridSystem}("lb")]["317_Hybrid", 1]
cons[PSI.ConstraintKey{HSS.StatusOutOn, HybridSystem}("ub")]["317_Hybrid", 288]
cons[PSI.ConstraintKey{HSS.RenewableReserveLimit, HybridSystem}("lb")]["317_Hybrid", 288]
exprs[PSI.ExpressionKey{HSS.TotalReserveInUpExpression, HybridSystem}("")]["317_Hybrid", 1]

vars[PSI.VariableKey{PSI.ReservationVariable, HybridSystem}("")]
