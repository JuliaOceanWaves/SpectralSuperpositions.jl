"""
    validate_superposition(
        data::AbstractMatrix,
        axis1::AbstractVector{<:Quantity},
        axis2::AbstractVector{<:Quantity}
    )
Recommended validation function for structs that inherit from AbstractSuperposition. Ensures
type consistency, axis/data sizes, axes values are increasing, moves spectral variables to
first axis, and saves useful attributes like coordinates, axes_types, and axes_names.
"""
function validate_superposition(
    data::AbstractMatrix,
    axis1::AbstractVector{<:Quantity},
    axis2::AbstractVector{<:Quantity}
)
    size(data) == (length(axis1), length(axis2)) ||
        throw(DimensionMismatch("Data and axes sizes do not match!"))
    _check_typeconsistency(data)
    _check_typeconsistency(axis1)
    _check_typeconsistency(axis2)
    data, axis1, axis2 = _ensure_increasing_axes(data, axis1, axis2)
    if isdirection(axis1) && isspectralvariable(axis2)
        data = permutedims(data)
    end

    coordinates, axis1, axis2 = _check_superposition_axes(axis1, axis2)
    axes_types = (axestypes(axis1), axestypes(axis2))
    axes_names = axes_types[1] == axes_types[2] ?
                 (Symbol(string(axes_types[1]) * "_1"),
                     Symbol(string(axes_types[2]) * "_2")) :
                 axes_types

    return (
        data = data,
        axis1 = axis1,
        axis2 = axis2,
        coordinates = coordinates,
        axestypes = axes_types,
        axesnames = axes_names
    )
end

Base.size(x::AbstractSuperposition) = size(x.data)
Base.eltype(x::AbstractSuperposition) = eltype(x.data)
Base.eltype(::Type{<:AbstractSuperposition{TDAT}}) where {TDAT} = TDAT
Base.IndexStyle(::Type{<:AbstractSuperposition}) = IndexLinear()
function Base.copy(x::AbstractSuperposition)
    rebuild_superposition(x, copy(x.data), copy(x.axis1), copy(x.axis2))
end

function Base.getindex(x::AbstractSuperposition, i::Int)
    return getindex(x.data, i)
end
Base.getindex(x::AbstractSuperposition, i::CartesianIndex) = getindex(x.data, i)
Base.getindex(x::AbstractSuperposition, ::Colon) = getindex(x, :, :)
function Base.getindex(x::AbstractSuperposition, I::Vararg{Int,2})
    return getindex(x.data, I...)
end
function Base.getindex(x::AbstractSuperposition, I...)
    selection = getindex(AxisArray(x), _axis_selectors(AxisArrays.axes(x), I...)...)
    selection isa AxisArray || return selection
    return rebuild_superposition(x, selection)
end
Base.setindex!(x::AbstractSuperposition, v, i::Int) = setindex!(x.data, v, i)
Base.setindex!(x::AbstractSuperposition, v, I::Vararg{Int,2}) = (x.data[I...] = v)

Base.BroadcastStyle(::Type{<:AbstractSuperposition}) = Broadcast.ArrayStyle{AbstractSuperposition}()

function Base.similar(x::AbstractSuperposition, ::Type{S}, dims::Dims) where {S}
    (dims != size(x)) && return similar(x.data, S, dims)
    return rebuild_superposition(x, similar(x.data, S, dims), x.axis1, x.axis2)
end

function Base.similar(
    bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{AbstractSuperposition}},
    ::Type{S}
) where {S}
    sp = _find_first_in_broadcast(bc.args, AbstractSuperposition)
    sp === nothing && return similar(Array{S}, axes(bc))
    _check_axes_in_broadcast(bc.args, sp)
    shape = Base.to_shape(axes(bc))
    return similar(sp, S, shape)
end

for op in (:(==), :(!=), :(<), :(<=), :(>), :(>=))
    @eval begin
        function Broadcast.broadcasted(
            ::typeof($op),
            a::AbstractSuperposition,
            b::AbstractSuperposition
        )
            _axes_match(a, b) ||
                throw(DimensionMismatch(
                    "AbstractSuperposition axes must match for broadcasting."))
            return Broadcast.broadcast($op, a.data, b.data)
        end

        function Broadcast.broadcasted(
            ::typeof($op),
            a::AbstractSuperposition,
            b
        )
            return Broadcast.broadcast($op, a.data, b)
        end

        function Broadcast.broadcasted(
            ::typeof($op),
            a,
            b::AbstractSuperposition
        )
            return Broadcast.broadcast($op, a, b.data)
        end
    end
end

function Base.:(==)(a::AbstractSuperposition, b::AbstractSuperposition)
    return (a.axis1 == b.axis1) && (a.axis2 == b.axis2) && (a.data == b.data)
end

function Base.isapprox(a::AbstractSuperposition, b::AbstractSuperposition; kwargs...)
    approx_ax1 = isapprox(a.axis1, b.axis1)
    approx_ax2 = isapprox(a.axis2, b.axis2)
    approx_data = isapprox(a.data, b.data; kwargs...)
    return (approx_ax1 && approx_ax2 && approx_data)
end

function Base.getindex(x::AbstractSuperposition; kwargs...)
    selection = getindex(AxisArray(x);
        _axis_selector_kwargs(x.axesnames, AxisArrays.axes(x), kwargs)...)
    return rebuild_superposition(x, selection)
end

function Base.setindex!(x::AbstractSuperposition, v; kwargs...)
    y = AxisArray(x)
    setindex!(y, v; _axis_selector_kwargs(x.axesnames, AxisArrays.axes(x), kwargs)...)
    x.data .= y.data
    return nothing
end

function Base.getindex(
    x::AbstractSuperposition,
    i::Vararg{Union{Quantity,ClosedInterval{<:Quantity}},2}
)
    kwargs = Dict()
    for (k, v) in zip(x.axesnames, i)
        kwargs[k] = v
    end
    return getindex(x; kwargs...)
end

function Base.setindex!(
    x::AbstractSuperposition,
    v::Any,
    i::Vararg{Union{Quantity,ClosedInterval{<:Quantity}},2}
)
    kwargs = Dict()
    for (key, value) in zip(x.axesnames, i)
        kwargs[key] = value
    end
    setindex!(x, v; kwargs...)
    return nothing
end

"""
    superposition_unit_aliases(::AbstractSuperposition)
Default symbol for getting the units of the data.
"""
superposition_unit_aliases(::AbstractSuperposition) = (:superposition,)

"""
    unit(x::AbstractSuperposition, quantity::Symbol)
    unit(x::AbstractSuperposition)

Extend `Unitful.unit` for abstract superposition.

The `quantity` can be `:axis` (or the axis name) or `:integral`.
These return the units of the spectral-variable axis, integral quantity, or the superposition data quantity.
The default is `quantity=:superposition`.
"""
function unit(x::AbstractSuperposition, quantity::Symbol)::Units
    ux, u1, u2 = unit(eltype(x)), unit(eltype(x.axis1)), unit(eltype(x.axis2))
    (quantity == :axis1) && return u1
    (quantity == :axis2) && return u2
    (quantity == x.axesnames[1]) && return u1
    (quantity == x.axesnames[2]) && return u2
    (quantity == :integral) && return ux * u1 * u2
    (quantity in superposition_unit_aliases(x)) && return ux
    throw(ArgumentError("Unknown `quantity`."))
end

unit(x::AbstractSuperposition) = unit(x, first(superposition_unit_aliases(x)))

# convert to/from AxisArray
function AxisArray(x::AbstractSuperposition)
    axis1 = Axis{x.axesnames[1]}(x.axis1)
    axis2 = Axis{x.axesnames[2]}(x.axis2)
    return AxisArray(x.data, axis1, axis2)
end
