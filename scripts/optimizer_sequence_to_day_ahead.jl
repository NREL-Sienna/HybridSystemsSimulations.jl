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

sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys_noForecast")
sys_rts_merchant = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")

# There is no Wind + Thermal in a Single Bus.
# We will try to pick the Wind in 317 bus Chuhsi
# It does not have thermal and load, so we will pick the adjacent bus 318: Clark
bus_to_add = "Chuhsi" # "Barton"
add_da_forecast_in_5_mins_to_rt!(sys_rts_merchant, sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_da)
add_hybrid_to_chuhsi_bus!(sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_merchant)
add_hybrid_to_chuhsi_bus!(sys_rts_merchant)

interval_DA = Hour(24)
horizon_DA = 24
transform_single_time_series!(sys_rts_da, horizon_DA, interval_DA)
interval_RT = Hour(24)
horizon_RT = 24 * 12
transform_single_time_series!(sys_rts_merchant, horizon_RT, interval_RT)

sys = sys_rts_merchant
sys.internal.ext = Dict{String, DataFrame}()
dic = PSY.get_ext(sys)

# Add prices to ext. Only three days.
bus_name = "chuhsi"
dic["λ_da_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_DA_prices.csv", DataFrame)
dic["λ_rt_df"] =
    CSV.read("scripts/simulation_pipeline/inputs/$(bus_name)_RT_prices.csv", DataFrame)
dic["horizon_RT"] = horizon_merchant_rt
dic["horizon_DA"] = horizon_merchant_da

hy_sys = first(get_components(HybridSystem, sys))
PSY.set_ext!(hy_sys, deepcopy(dic))

# Set decision model for Optimizer
decision_optimizer_DA = DecisionModel(
    MerchantHybridEnergyCase,
    ProblemTemplate(CopperPlatePowerModel),
    sys,
    optimizer=Xpress.Optimizer,
    calculate_conflict=true,
    store_variable_names=true;
    name="MerchantHybridEnergyCase_DA",
)

#=
build!(decision_optimizer_DA; output_dir=pwd())
solve!(decision_optimizer_DA)

#results = ProblemResults(decision_optimizer_DA)
#var_results = results.variable_values
#rt_bid_out = read_variable(results, "EnergyRTBidOut__HybridSystem")
da_bid_out = var_results[PSI.VariableKey{HSS.EnergyDABidOut, HybridSystem}("")]

cons = decision_optimizer_DA.internal.container.constraints
vars = decision_optimizer_DA.internal.container.variables
cons[PSI.ConstraintKey{HSS.StatusOutOn, HybridSystem}("")]["317_Hybrid", 1]
JuMP.upper_bound(
    vars[PSI.VariableKey{HSS.EnergyRTBidOut, HybridSystem}("")]["317_Hybrid", 1],
)
=#

mipgap = 0.01
num_steps = 3
start_time = DateTime("2020-10-03T00:00:00")

template_uc_copperplate = get_uc_copperplate_template(sys_rts_da)
# Set Hybrid in UC as FixedDA
set_device_model!(
    template_uc_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridEnergyOnlyFixedDA;
        attributes=Dict{String, Any}("cycling" => false),
    ),
)

# Construct decision models for simulation
models = SimulationModels(
    decision_models=[
        decision_optimizer_DA,
        DecisionModel(
            template_uc_copperplate,
            sys_rts_da;
            name="UC",
            optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => mipgap),
            system_to_file=false,
            initialize_model=true,
            optimizer_solve_log_print=false,
            direct_mode_optimizer=true,
            rebuild_model=false,
            store_variable_names=true,
            #check_numerical_bounds=false,
        ),
    ],
)

# Set-up the sequence Optimizer-UC
sequence = SimulationSequence(
    models=models,
    feedforwards=Dict(
        "UC" => [
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyDABidOut,
                affected_values=[ActivePowerOutVariable],
            ),
            FixValueFeedforward(
                component_type=PSY.HybridSystem,
                source=EnergyDABidIn,
                affected_values=[ActivePowerInVariable],
            ),
        ],
    ),
    ini_cond_chronology=InterProblemChronology(),
)

sim = Simulation(
    name="compact_sim",
    steps=num_steps,
    models=models,
    sequence=sequence,
    initial_time=start_time,
    simulation_folder=mktempdir(cleanup=true),
)

build!(sim)

execute!(sim; enable_progress_bar=true)

results = SimulationResults(sim)
result_opt = get_decision_problem_results(results, "MerchantHybridEnergyCase_DA")

da_bid_out = read_variable(result_opt, "EnergyDABidOut__HybridSystem")
da_bid_in = read_variable(result_opt, "EnergyDABidIn__HybridSystem")

full_horizon = 72
da_bid_out_realized = zeros(full_horizon)
da_horizon = 24
i = 0
for (k, bid) in da_bid_out
    da_bid_out_realized[(da_horizon * i + 1):((i + 1) * da_horizon)] = bid[!, 1]
    i = i + 1
end

da_bid_in_realized = zeros(full_horizon)
i = 0
for (k, bid) in da_bid_in
    da_bid_in_realized[(da_horizon * i + 1):((i + 1) * da_horizon)] = bid[!, 1]
    i = i + 1
end

plot([
    scatter(y=da_bid_out_realized, name="Bid Out", line_shape="hv"),
    scatter(y=-da_bid_in_realized, name="Bid In", line_shape="hv"),
])
