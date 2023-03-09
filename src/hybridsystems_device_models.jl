function get_default_time_series_names(
    ::Type{<:PSY.HybridSystem},
    ::Type{<:Union{FixedOutput, AbstractHybridFormulation}},
)
    return Dict{Type{<:TimeSeriesParameter}, String}(
        ActivePowerTimeSeriesParameter => "max_active_power",
    )
end

function get_default_attributes(
    ::Type{<:PSY.HybridSystem},
    ::Type{<:AbstractHybridFormulation},
)
    return Dict{String, Any}("reservation" => true, "storage_reservation" => true)
end
