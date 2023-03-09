function PSI.get_default_time_series_names(
    ::Type{<:PSY.HybridSystem},
    ::Type{<:Union{PSI.FixedOutput, AbstractHybridFormulation}},
)
    return Dict{Type{<:PSI.TimeSeriesParameter}, String}(
        ActivePowerTimeSeriesParameter => "max_active_power",
    )
end

function PSI.get_default_attributes(
    ::Type{<:PSY.HybridSystem},
    ::Type{<:Union{PSI.FixedOutput, AbstractHybridFormulation}},
)
    return Dict{String, Any}("reservation" => true, "storage_reservation" => true)
end
