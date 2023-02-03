function modify_ren_curtailment_cost!(sys)
    rdispatch = get_components(RenewableDispatch, sys)
    for ren in rdispatch
        # We consider 15 $/MWh as a reasonable cost for renewable curtailment
        cost = TwoPartCost(15.0, 0.0)
        set_operation_cost!(ren, cost)
    end
    return
end
