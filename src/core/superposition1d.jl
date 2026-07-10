"""
    validate_superposition1d(
        data::AbstractVector,
        axis::AbstractVector{<:Quantity}
    )
Recommended validation function for structs that inherit from AbstractSuperposition1D. 
Ensures type consistency, axis/data sizes, axes values are increasing, moves spectral 
variables to first axis, and saves useful attributes like coordinates, axes_types, and 
axes_names.
"""
function validate_superposition1d(
    data::AbstractVector,
    axis::AbstractVector{<:Quantity}
)
    length(data) == length(axis) ||
        throw(DimensionMismatch("Data and axis lengths do not match!"))
    _check_typeconsistency(data)
    _check_typeconsistency(axis)
    data, axis = _ensure_increasing_axis(data, axis)
    isspectralvariable(axis) ||
        throw(ArgumentError("Axis must be a spectral-variable type."))
    _check_strictly_positive_finite_spectral_axis(axis)

    axistype = axisname = axestypes(axis)
    return (
        data = data,
        axis = axis,
        axistype = axistype,
        axisname = axisname
    )
end

Base.size(x::AbstractSuperposition1D) = size(x.data)
Base.eltype(x::AbstractSuperposition1D) = eltype(x.data)
Base.eltype(::Type{<:AbstractSuperposition1D{TDAT}}) where {TDAT} = TDAT
Base.IndexStyle(::Type{<:AbstractSuperposition1D}) = IndexLinear()
function Base.copy(x::AbstractSuperposition1D)
    rebuild_superposition(x, copy(x.data), copy(x.axis))
end

Base.getindex(x::AbstractSuperposition1D, i::Int) = getindex(x.data, i)
function Base.getindex(x::AbstractSuperposition1D, I...)
    return getindex(AxisArray(x), _axis_selectors(AxisArrays.axes(x), I...)...)
end
Base.setindex!(x::AbstractSuperposition1D, v, i::Int) = setindex!(x.data, v, i)

Base.BroadcastStyle(::Type{<:AbstractSuperposition1D}) = Broadcast.ArrayStyle{AbstractSuperposition1D}()

function Base.similar(x::AbstractSuperposition1D, ::Type{S}, dims::Dims) where {S}
    (dims != size(x)) && return similar(x.data, S, dims)
    return rebuild_superposition(x, similar(x.data, S, dims), x.axis)
end

function Base.similar(
    bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{AbstractSuperposition1D}},
    ::Type{S}
) where {S}
    sp = _find_first_in_broadcast(bc.args, AbstractSuperposition1D)
    sp === nothing && return similar(Array{S}, axes(bc))
    _check_axes_in_broadcast(bc.args, sp)
    shape = Base.to_shape(axes(bc))
    return similar(sp, S, shape)
end

for op in (:(==), :(!=), :(<), :(<=), :(>), :(>=))
    @eval begin
        function Broadcast.broadcasted(
            ::typeof($op),
            a::AbstractSuperposition1D,
            b::AbstractSuperposition1D
        )
            _axes_match(a, b) ||
                throw(DimensionMismatch(
                    "AbstractSuperposition1D axes must match for broadcasting."))
            return Broadcast.broadcast($op, a.data, b.data)
        end

        function Broadcast.broadcasted(
            ::typeof($op),
            a::AbstractSuperposition1D,
            b
        )
            return Broadcast.broadcast($op, a.data, b)
        end

        function Broadcast.broadcasted(
            ::typeof($op),
            a,
            b::AbstractSuperposition1D
        )
            return Broadcast.broadcast($op, a, b.data)
        end
    end
end

function Base.:(==)(a::AbstractSuperposition1D, b::AbstractSuperposition1D)
    return (a.axis == b.axis) && (a.data == b.data)
end

function Base.isapprox(a::AbstractSuperposition1D, b::AbstractSuperposition1D; kwargs...)
    return (isapprox(a.axis, b.axis) && isapprox(a.data, b.data; kwargs...))
end

function Base.getindex(x::AbstractSuperposition1D; kwargs...)
    return getindex(AxisArray(x);
        _axis_selector_kwargs((x.axisname,), AxisArrays.axes(x), kwargs)...)
end

function Base.setindex!(x::AbstractSuperposition1D, v; kwargs...)
    y = AxisArray(x)
    setindex!(y, v; _axis_selector_kwargs((x.axisname,), AxisArrays.axes(x), kwargs)...)
    x.data .= y.data
    return nothing
end

function Base.getindex(
    x::AbstractSuperposition1D,
    i::Union{Quantity,ClosedInterval{<:Quantity}}
)
    kwargs = Dict(x.axisname => i,)
    return getindex(x; kwargs...)
end

function Base.setindex!(
    x::AbstractSuperposition1D,
    v::Any,
    i::Union{Quantity,ClosedInterval{<:Quantity}}
)
    y = AxisArray(x)
    setindex!(y, v; x.axisname => _axis_selector(x.axis, i))
    x.data .= y.data
    return nothing
end

"""
    superposition_unit_aliases(::AbstractSuperposition1D)
Default symbol for getting the units of the data.
"""
superposition_unit_aliases(::AbstractSuperposition1D) = (:superposition,)

"""
    unit(x::AbstractSuperposition1D, quantity::Symbol)
    unit(x::AbstractSuperposition1D)

Extend `Unitful.unit` for abstract superposition.

The `quantity` can be `:axis` (or the axis name) or `:integral`.
These return the units of the spectral-variable axis, integral quantity, or the superposition data quantity.
The default is `quantity=:superposition`.
"""
function unit(x::AbstractSuperposition1D, quantity::Symbol)::Units
    ux, ua = unit(eltype(x)), unit(eltype(x.axis))
    (quantity == :axis) && return ua
    (quantity == x.axisname) && return ua
    (quantity == :integral) && return ux * ua
    (quantity in superposition_unit_aliases(x)) && return ux
    throw(ArgumentError("Unknown `quantity`."))
end

# convert to/from AxisArray
unit(x::AbstractSuperposition1D) = unit(x, first(superposition_unit_aliases(x)))

function AxisArray(x::AbstractSuperposition1D)
    axis = Axis{x.axisname}(x.axis)
    return AxisArray(x.data, axis)
end
