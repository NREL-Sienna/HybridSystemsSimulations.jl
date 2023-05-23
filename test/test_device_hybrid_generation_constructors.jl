@testset "Hybrid DCPLossLess with HybridEnergyOnlyDispatch formulation" begin
    device_model = DeviceModel(
        PSY.HybridSystem,
        HybridEnergyOnlyDispatch;
        attributes=Dict{String, Any}("cycling" => false),
    )
    sys = PSB.build_system(PSITestSystems, "c_sys5_hybrid")

    # Parameters Testing
    model =
        DecisionModel(MockOperationProblem, DCPPowerModel, sys; store_variable_names=true)
    mock_construct_device!(model, device_model)
    moi_tests(model, 816, 0, 720, 192, 192, true)
    psi_checkobjfun_test(model, GAEVF)
end

@testset "Hybrid ACPPowerModel with HybridEnergyOnlyDispatch formulation" begin
    device_model = DeviceModel(
        PSY.HybridSystem,
        HybridEnergyOnlyDispatch;
        attributes=Dict{String, Any}("cycling" => false),
    )
    sys = PSB.build_system(PSITestSystems, "c_sys5_hybrid")

    # No Parameters Testing
    model = DecisionModel(MockOperationProblem, StandardPTDFModel, sys)
    mock_construct_device!(model, device_model)
    moi_tests(model, 816, 0, 720, 192, 192, true)
    psi_checkobjfun_test(model, GAEVF)
end

@testset "Hybrid DCPLossLess with HybridBasicDispatch formulation" begin
    device_model = DeviceModel(
        PSY.HybridSystem,
        HybridBasicDispatch;
        attributes=Dict{String, Any}("cycling" => false),
    )
    sys = PSB.build_system(PSITestSystems, "c_sys5_hybrid")

    # Parameters Testing
    model =
        DecisionModel(MockOperationProblem, DCPPowerModel, sys; store_variable_names=true)
    mock_construct_device!(model, device_model)
    moi_tests(model, 816, 0, 720, 192, 192, true)
    psi_checkobjfun_test(model, GAEVF)
end

@testset "Hybrid ACPPowerModel with HybridBasicDispatch formulation" begin
    device_model = DeviceModel(
        PSY.HybridSystem,
        HybridBasicDispatch;
        attributes=Dict{String, Any}("cycling" => false),
    )
    sys = PSB.build_system(PSITestSystems, "c_sys5_hybrid")

    # No Parameters Testing
    model = DecisionModel(MockOperationProblem, StandardPTDFModel, sys)
    mock_construct_device!(model, device_model)
    moi_tests(model, 816, 0, 720, 192, 192, true)
    psi_checkobjfun_test(model, GAEVF)
end
