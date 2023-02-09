using DataFrames

function get_psi_ptdf_lmps(res, ptdf)
    # Obtain Dual of Copper Plate
    dic_cp = read_realized_duals(res, ["CopperPlateBalanceConstraint__System"])
    cp_duals = dic_cp["CopperPlateBalanceConstraint__System"]
    dates = cp_duals[:, "DateTime"]
    # Create Matrix of LMPs (Time x Buses)
    λ = Matrix{Float64}(cp_duals[:, propertynames(cp_duals) .!= :DateTime])

    # Obtain Dual of Line Constraints
    dic_flow = read_realized_duals(res, ["NetworkFlowConstraint__Line"])
    flow_duals = dic_flow["NetworkFlowConstraint__Line"]

    # Obtain Matrix of LMPs of Line Congestions
    line_names = names(flow_duals)
    popfirst!(line_names)
    μ = Matrix{Float64}(flow_duals[:, line_names])

    # Remove Transformers from PTDF
    ix_lines = Vector{Int}()
    lookup_lines = ptdf.lookup[1]
    lookup_buses = ptdf.lookup[2]
    for l in line_names
        push!(ix_lines, lookup_lines[l])
    end
    ptdf_no_tx = ptdf.data[ix_lines, :]

    # 
    buses = get_components(Bus, get_system(res))
    lmps = OrderedDict()
    for bus in buses
        lmps[get_name(bus)] = μ * ptdf_no_tx[:, lookup_buses[get_number(bus)]]
    end
    lmp = λ .+ DataFrames.DataFrame(lmps)
    lmp_sorted = lmp[!, sort(propertynames(lmp))]
    insertcols!(lmp_sorted, 1, "DateTime" => dates)
    return lmp_sorted
end

function get_psi_dcp_lmps(res)
    dict = read_realized_duals(res, ["NodalBalanceActiveConstraint__Bus"])
    df_lmp = dict["NodalBalanceActiveConstraint__Bus"]
    return df_lmp
end

function get_copperplate_prices(res)
    # Obtain Dual of Copper Plate
    dic_cp = read_realized_duals(res, ["CopperPlateBalanceConstraint__System"])
    return dic_cp["CopperPlateBalanceConstraint__System"]
end

function get_normalized_bus_dcp_prices(
    prices_dcp,
    bus_name::String,
    time_length::Float64,
    base_power::Float64,
    multiplier::Float64,
)
    price = prices_dcp[:, bus_name]
    dates = prices_dcp[:, "DateTime"]
    normalized_price = multiplier * price / (base_power * time_length)
    df = DataFrame()
    df[!, "DateTime"] = dates
    df[!, bus_name] = normalized_price
    return df
end
