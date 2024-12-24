using Revise
using Pkg
Pkg.activate("test")
Pkg.instantiate()

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
const IS = InfrastructureSystems

# Load Optimization and Useful Packages
using JuMP
using Logging
using Dates
using CSV
using TimeSeries

@static if haskey(ENV, "NREL_CLUSTER")
    using Gurobi
    mipgap = 0.001
    optimizer = optimizer_with_attributes(
        Gurobi.Optimizer,
        "Threads" => (length(Sys.cpu_info()) ÷ 2) - 1,
        "MIPGap" => mipgap,
        "TimeLimit" => 3000,
    )
else
    using Xpress
    mipgap = 0.03
    optimizer = optimizer_with_attributes(
        Xpress.Optimizer,
        "MAXTIME" => 3000, # Stop after 50 Minutes
        "THREADS" => length(Sys.cpu_info()) ÷ 2,
        "MIPRELSTOP" => mipgap,
    )
end

if isempty(ARGS)
    push!(ARGS, "use_services")
    push!(ARGS, "2020-07-10T00:00:00")
    push!(ARGS, "4")
end

###############################
######## Load Scripts #########
###############################
include("../get_templates.jl")
include("../modify_systems.jl")
include("../price_generation_utils.jl")
include("../build_simulation_cases_reserves.jl")
include("../utils.jl")

if isfile("modified_RTS_GMLC_DA_sys_noForecast.json")
    sys_rts_da = System("modified_RTS_GMLC_DA_sys_noForecast.json")
else
    sys_rts_da = build_system(PSISystems, "modified_RTS_GMLC_DA_sys_noForecast")
    to_json(sys_rts_da, "modified_RTS_GMLC_DA_sys_noForecast.json")
end

if isfile("modified_RTS_GMLC_RT_sys_noForecast.json")
    sys_rts_rt = System("modified_RTS_GMLC_RT_sys_noForecast.json")
else
    sys_rts_rt = build_system(PSISystems, "modified_RTS_GMLC_RT_sys_noForecast")
    to_json(sys_rts_rt, "modified_RTS_GMLC_RT_sys_noForecast.json")
end
sys_rts_em = System("modified_RTS_GMLC_RT_sys_noForecast.json")

bus_to_add = "Chuhsi" # "Barton"
add_da_forecast_in_5_mins_to_rt!(sys_rts_rt, sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_da)
add_hybrid_to_chuhsi_bus!(sys_rts_da)
modify_ren_curtailment_cost!(sys_rts_rt)
add_hybrid_to_chuhsi_bus!(sys_rts_rt)
modify_ren_curtailment_cost!(sys_rts_em)
add_hybrid_to_chuhsi_bus!(sys_rts_em)

# Define DA and RT intervals and horizon. It must be ::Periods
interval_DA = Hour(24)
horizon_DA = Hour(72)
transform_single_time_series!(sys_rts_da, horizon_DA, interval_DA)
interval_RT = Hour(1)
horizon_RT = Hour(12)
transform_single_time_series!(sys_rts_rt, horizon_RT, interval_RT)

served_fraction_map = Dict(
    "Spin_Up_R2" => 0.00,
    "Spin_Up_R3" => 0.00,
    "Reg_Up" => 0.3,
    "Spin_Up_R1" => 0.00,
    "Flex_Up" => 0.1,
    "Reg_Down" => 0.3,
    "Flex_Down" => 0.1,
)

if ARGS[1] == "use_services"
    formulation = HybridDispatchWithReserves
else
    formulation = HybridEnergyOnlyDispatch
end

for sys in [sys_rts_da, sys_rts_rt]
    services = get_components(VariableReserve, sys)
    hy_sys = first(get_components(HybridSystem, sys))
    for service in services
        serv_name = get_name(service)
        serv_frac = served_fraction_map[serv_name]
        set_deployed_fraction!(service, serv_frac)
        if contains(serv_name, "Spin_Up_R1") |
           contains(serv_name, "Spin_Up_R2") |
           contains(serv_name, "Flex")
            continue
        else
            if formulation == HybridDispatchWithReserves
                add_service!(hy_sys, service, sys)
            end
        end
    end
end

###############################
###### Create Templates #######
###############################

# CopperPlate
template_uc_copperplate = get_uc_copperplate_template(sys_rts_da)
template_ed_copperplate = get_ed_copperplate_template(sys_rts_rt)

# PTDF Bounded
template_uc_ptdf = get_uc_ptdf_template(sys_rts_da)
template_ed_ptdf = get_ed_ptdf_template(sys_rts_rt)

# PTDF Unbounded
template_uc_unbounded_ptdf = get_uc_ptdf_unbounded_template(sys_rts_da)
template_ed_unbounded_ptdf = get_ed_ptdf_unbounded_template(sys_rts_rt)

# DCP
template_uc_dcp = get_uc_dcp_template()
template_ed_dcp = get_ed_dcp_template()

set_device_model!(
    template_uc_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        formulation;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "storage_reservation" => true,
            "energy_target" => false,
            "cycling" => true,
            "regularization" => false,
        ),
    ),
)

set_device_model!(
    template_ed_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        formulation;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "storage_reservation" => true,
            "energy_target" => false,
            "cycling" => false,
            "regularization" => true,
        ),
    ),
)

template_pf_copperplate = deepcopy(template_ed_copperplate)
empty!(template_pf_copperplate.services)

set_device_model!(
    template_pf_copperplate,
    DeviceModel(
        PSY.HybridSystem,
        HybridEnergyOnlyDispatch;
        attributes=Dict{String, Any}(
            "reservation" => true,
            "storage_reservation" => true,
            "energy_target" => false,
            "cycling" => false,
            "regularization" => true,
        ),
    ),
)

###############################
###### Simulation Params ######
###############################

starttime = DateTime(ARGS[2])
num_steps = parse(Int, ARGS[3])

models = SimulationModels(
    decision_models=[
        DecisionModel(
            template_uc_copperplate,
            sys_rts_da;
            name="UC",
            optimizer=optimizer,
            system_to_file=false,
            initialize_model=true,
            optimizer_solve_log_print=false,
            direct_mode_optimizer=true,
            rebuild_model=false,
            store_variable_names=true,
            #check_numerical_bounds=false,
        ),
        DecisionModel(
            template_ed_copperplate,
            sys_rts_rt;
            name="ED",
            optimizer=optimizer,
            system_to_file=false,
            initialize_model=true,
            optimizer_solve_log_print=false,
            check_numerical_bounds=false,
            rebuild_model=false,
            calculate_conflict=true,
            store_variable_names=true,
            #export_pwl_vars = true,
        ),
    ],
    emulation_model=EmulationModel(
        template_pf_copperplate,
        sys_rts_em;
        name="PF",
        optimizer=optimizer,
    ),
)

# Set-up the sequence UC-ED
sequence = SimulationSequence(
    models=models,
    feedforwards=Dict(
        "ED" => [
            SemiContinuousFeedforward(
                component_type=ThermalStandard,
                source=OnVariable,
                affected_values=[ActivePowerVariable],
            ),
            LowerBoundFeedforward(
                component_type=VariableReserve{ReserveUp},
                source=ActivePowerReserveVariable,
                affected_values=[ActivePowerReserveVariable],
                add_slacks=true,
            ),
            LowerBoundFeedforward(
                component_type=VariableReserve{ReserveDown},
                source=ActivePowerReserveVariable,
                affected_values=[ActivePowerReserveVariable],
                add_slacks=true,
            ),
            CyclingChargeLimitFeedforward(
                component_type=PSY.HybridSystem,
                source=HSS.CyclingChargeUsage,
                affected_values=[HSS.CyclingChargeLimitParameter],
                penalty_cost=0.0,
            ),
            CyclingDischargeLimitFeedforward(
                component_type=PSY.HybridSystem,
                source=HSS.CyclingDischargeUsage,
                affected_values=[HSS.CyclingDischargeLimitParameter],
                penalty_cost=0.0,
            ),
        ],
        "PF" => [
            SemiContinuousFeedforward(;
                component_type=ThermalStandard,
                source=OnVariable,
                affected_values=[ActivePowerVariable],
            ),
        ],
    ),
    ini_cond_chronology=InterProblemChronology(),
)

starttime_str = string(starttime)
starttime_str = replace(starttime_str, ":" => "-")
sim_dcp = Simulation(
    name="centralized_sim_$(formulation)_$(starttime_str)",
    steps=num_steps,
    models=models,
    sequence=sequence,
    initial_time=starttime,
    simulation_folder=".",
)

build_dcp = build!(sim_dcp; console_level=Logging.Info, serialize=false)

execute_status = execute!(sim_dcp; enable_progress_bar=true)
