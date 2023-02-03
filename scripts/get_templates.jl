function set_uc_models!(template_uc)
    set_device_model!(template_uc, ThermalMultiStart, ThermalStandardUnitCommitment)
    set_device_model!(template_uc, ThermalStandard, ThermalStandardUnitCommitment)
    set_device_model!(template_uc, RenewableDispatch, RenewableFullDispatch)
    set_device_model!(template_uc, PowerLoad, StaticPowerLoad)
    set_device_model!(template_uc, Transformer2W, StaticBranchUnbounded)
    set_device_model!(template_uc, TapTransformer, StaticBranchUnbounded)
    set_device_model!(template_uc, HydroDispatch, FixedOutput)
    set_device_model!(template_uc, HydroEnergyReservoir, HydroDispatchRunOfRiver)
    set_device_model!(template_uc, GenericBattery, BookKeeping)
    set_service_model!(template_uc, ServiceModel(VariableReserve{ReserveUp}, RangeReserve))
    set_service_model!(
        template_uc,
        ServiceModel(VariableReserve{ReserveDown}, RangeReserve),
    )
    return
end

function update_ed_models!(template_ed)
    set_device_model!(template_ed, ThermalMultiStart, ThermalStandardDispatch)
    set_device_model!(template_ed, ThermalStandard, ThermalBasicDispatch)
    set_device_model!(template_ed, HydroDispatch, FixedOutput)
    set_device_model!(template_ed, HydroEnergyReservoir, HydroDispatchRunOfRiver)
    return
end

function set_ptdf_line_template!(template_uc)
    # Unbounded Branch for now
    set_device_model!(
        template_uc,
        DeviceModel(Line, StaticBranchUnbounded, duals=[NetworkFlowConstraint]),
    )
    return
end

function set_dcp_line_template!(template_uc)
    # Unbounded Branch for now
    set_device_model!(template_uc, DeviceModel(Line, StaticBranchUnbounded))
    return
end

function get_uc_dcp_template()
    template_uc = ProblemTemplate(
        NetworkModel(DCPPowerModel, use_slacks=true, duals=[NodalBalanceActiveConstraint]),
    )
    set_uc_models!(template_uc)
    set_dcp_line_template!(template_uc)
    return template_uc
end

function get_uc_ptdf_template(sys_rts_da)
    template_uc = ProblemTemplate(
        NetworkModel(
            StandardPTDFModel,
            use_slacks=true,
            PTDF=PTDF(sys_rts_da),
            duals=[CopperPlateBalanceConstraint],
        ),
    )
    set_uc_models!(template_uc)
    set_ptdf_line_template!(template_uc)
    return template_uc
end

function get_ed_dcp_template()
    template_ed = get_uc_dcp_template()
    update_ed_models!(template_ed)
    return template_ed
end

function get_ed_ptdf_template()
    template_ed = get_uc_ptdf_template(sys_rts_da)
    update_ed_models!(template_ed)
    return template_ed
end
