using Pkg
Pkg.activate("test")
Pkg.instantiate()

using Revise

# Load SIIP Packages

using PowerSimulations
using PowerSystems
using PowerSystemCaseBuilder
using InfrastructureSystems
import OrderedCollections: OrderedDict
const PSY = PowerSystems
const PSI = PowerSimulations
const PSB = PowerSystemCaseBuilder

# Load Optimization and Useful Packages
using Xpress
using JuMP
using Logging
using Dates

# Include scripts
include("get_templates.jl")
include("modify_systems.jl")
include("make_price_data.jl")

# Load Systems: DA + RT
sys_rts_da = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")
sys_rts_rt = build_system(PSITestSystems, "modified_RTS_GMLC_RT_sys")

systems = [sys_rts_da, sys_rts_rt]
for sys in systems
    modify_ren_curtailment_cost!(sys)
end

# PTDF templates
template_uc_ptdf = get_uc_ptdf_template(sys_rts_da)
template_ed_ptdf = get_ed_ptdf_template()

# DCP Templates
template_uc_dcp = get_uc_dcp_template()
template_ed_dcp = get_ed_dcp_template()

###############################
##### Run PTDF Simulation #####
###############################

models_ptdf = SimulationModels(
    decision_models=[
        DecisionModel(
            template_uc_ptdf,
            sys_rts_da;
            name="UC",
            optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.01),
            system_to_file=false,
            initialize_model=true,
            optimizer_solve_log_print=false,
            direct_mode_optimizer=true,
            rebuild_model=false,
            store_variable_names=true,
            #check_numerical_bounds=false,
        ),
        DecisionModel(
            template_ed_ptdf,
            sys_rts_rt;
            name="ED",
            optimizer=optimizer_with_attributes(Xpress.Optimizer),
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
)

# Set-up the sequence UC-ED
sequence_ptdf = SimulationSequence(
    models=models_ptdf,
    feedforwards=Dict(
        "ED" => [
            SemiContinuousFeedforward(
                component_type=ThermalStandard,
                source=OnVariable,
                affected_values=[ActivePowerVariable],
            ),
        ],
    ),
    ini_cond_chronology=InterProblemChronology(),
)

sim_ptdf = Simulation(
    name="compact_sim",
    steps=3,
    models=models_ptdf,
    sequence=sequence_ptdf,
    initial_time=DateTime("2020-10-01T00:00:00"),
    simulation_folder=mktempdir(cleanup=true),
);

build_out = build!(sim_ptdf; console_level=Logging.Info, serialize=false)

# Check Objective Function
#model = sim.models.decision_models[1] #UC
#obj_func = model.internal.container.objective_function

execute_status = execute!(sim_ptdf; enable_progress_bar=true);

results = SimulationResults(sim_ptdf; ignore_status=true)
results_ed = get_decision_problem_results(results, "ED")
ptdf = PTDF(sys_rts_rt)
prices_ptdf = make_psi_ptdf_lmps(results_ed, ptdf)

###############################
##### Run DCP Simulation ######
###############################

models_dcp = SimulationModels(
    decision_models=[
        DecisionModel(
            template_uc_dcp,
            sys_rts_da;
            name="UC",
            optimizer=optimizer_with_attributes(Xpress.Optimizer, "MIPRELSTOP" => 0.01),
            system_to_file=false,
            initialize_model=true,
            optimizer_solve_log_print=false,
            direct_mode_optimizer=true,
            rebuild_model=false,
            store_variable_names=true,
            #check_numerical_bounds=false,
        ),
        DecisionModel(
            template_ed_dcp,
            sys_rts_rt;
            name="ED",
            optimizer=optimizer_with_attributes(Xpress.Optimizer),
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
)

# Set-up the sequence UC-ED
sequence_dcp = SimulationSequence(
    models=models_dcp,
    feedforwards=Dict(
        "ED" => [
            SemiContinuousFeedforward(
                component_type=ThermalStandard,
                source=OnVariable,
                affected_values=[ActivePowerVariable],
            ),
        ],
    ),
    ini_cond_chronology=InterProblemChronology(),
)

sim_dcp = Simulation(
    name="compact_sim",
    steps=3,
    models=models_dcp,
    sequence=sequence_dcp,
    initial_time=DateTime("2020-10-01T00:00:00"),
    simulation_folder=mktempdir(cleanup=true),
);

build_dcp = build!(sim_dcp; console_level=Logging.Info, serialize=false)

execute_status = execute!(sim_dcp; enable_progress_bar=true);

results_dcp = SimulationResults(sim_dcp; ignore_status=true)
results_ed_dcp = get_decision_problem_results(results_dcp, "ED")
prices_dcp = make_psi_dcp_lmps(results_ed_dcp)
