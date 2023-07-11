@testset "Test HybridSystem Merchant Decision Model Only Energy" begin

    horizon_merchant_rt = 288
    horizon_merchant_da = 24
    sys_rts_merchant = PSB.build_RTS_GMLC_RT_sys(
        raw_data=PSB.RTS_DIR,
        horizon=horizon_merchant_rt,
        interval=Hour(24),
    )
    sys_rts_da = PSB.build_RTS_GMLC_DA_sys(raw_data=PSB.RTS_DIR, horizon=24)
    
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
        CSV.read(joinpath(TEST_DIR, "inputs/$(bus_name)_DA_prices.csv"), DataFrame)
    dic["λ_rt_df"] =
        CSV.read(joinpath(TEST_DIR, "inputs/$(bus_name)_RT_prices.csv"), DataFrame)
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
    
    build!(decision_optimizer_DA; output_dir=pwd())



end