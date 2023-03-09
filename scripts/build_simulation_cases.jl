# No emulation
function build_simulation_case(
    template_uc,
    template_ed,
    sys_da::System,
    sys_rt::System,
    num_steps::Int,
    mipgap::Float64,
    start_time,
)
    models = SimulationModels(
        decision_models=[
            DecisionModel(
                template_uc,
                sys_da;
                name="UC",
                optimizer=optimizer_with_attributes(
                    Xpress.Optimizer,
                    "MIPRELSTOP" => mipgap,
                ),
                system_to_file=false,
                initialize_model=true,
                optimizer_solve_log_print=true,
                direct_mode_optimizer=true,
                rebuild_model=false,
                store_variable_names=true,
                #check_numerical_bounds=false,
            ),
            DecisionModel(
                template_ed,
                sys_rt;
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
    sequence = SimulationSequence(
        models=models,
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

    sim = Simulation(
        name="compact_sim",
        steps=num_steps,
        models=models,
        sequence=sequence,
        initial_time=start_time,
        simulation_folder=mktempdir(cleanup=true),
    )

    return sim
end

# No emulation
function build_simulation_case_optimizer(
    template_uc,
    decision_optimizer,
    sys_da::System,
    sys_rt::System,
    num_steps::Int,
    mipgap::Float64,
    start_time,
)
    models = SimulationModels(
        decision_models=[
            decision_optimizer,
            DecisionModel(
                template_uc,
                sys_da;
                name="UC",
                optimizer=optimizer_with_attributes(
                    Xpress.Optimizer,
                    "MIPRELSTOP" => mipgap,
                ),
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
                    component_type=HybridSystem,
                    source=energyDABidOut,
                    affected_values=[ActivePowerOutVariable],
                ),
                FixValueFeedforward(
                    component_type=HybridSystem,
                    source=energyDABidIn,
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

    return sim
end
