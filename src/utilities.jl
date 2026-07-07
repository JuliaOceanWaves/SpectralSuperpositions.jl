# Shared helper utilities for SpectralSuperpositions

@inline function _check_typeconsistency(x::AbstractArray)::Nothing
    consistent = all(y -> typeof(y) == eltype(x), x)
    !consistent && throw(ArgumentError("All elements of array must be of same type."))
    return nothing
end

@inline function _ensure_increasing_axes(data, axis1, axis2)
    if issorted(axis1)
        data1 = data
    elseif issorted(axis1; rev=true)
        axis1 = reverse(axis1)
        data1 = reverse(data, dims=1)
    else
        throw(ArgumentError("Axis 1 must be monotonic."))
    end

    if issorted(axis2)
        return data1, axis1, axis2
    elseif issorted(axis2; rev=true)
        axis2 = reverse(axis2)
        return reverse(data1, dims=2), axis1, axis2
    else
        throw(ArgumentError("Axis 2 must be monotonic."))
    end
end

@inline function _ensure_increasing_axis(data, axis)
    if issorted(axis)
        return data, axis
    elseif issorted(axis; rev=true)
        axis = reverse(axis)
        return reverse(data), axis
    else
        throw(ArgumentError("Axis must be monotonic."))
    end
end

@inline function _check_strictly_positive_finite_spectral_axis(axis::AbstractVector)
    if first(axis) <= zero(first(axis))
        throw(ArgumentError("Spectral-variable axis values must be positive."))
    elseif !all(isfinite, axis)
        throw(ArgumentError("Spectral-variable axis values must be finite."))
    end
    return nothing
end

@inline function _check_superposition_axes(axis1::AbstractVector, axis2::AbstractVector)
    axis1_is_spectral = isspectralvariable(axis1)
    axis2_is_spectral = isspectralvariable(axis2)
    if axis1_is_spectral && axis2_is_spectral
        return :cartesian, axis1, axis2
    elseif axis1_is_spectral && isdirection(axis2)
        _check_strictly_positive_finite_spectral_axis(axis1)
        return :polar, axis1, axis2
    elseif axis2_is_spectral && isdirection(axis1)
        @warn "Swapping order of axes to have direction as second axis."
        _check_strictly_positive_finite_spectral_axis(axis2)
        return :polar, axis2, axis1
    end
    throw(ArgumentError("Axes must define a cartesian or polar coordinate."))
end

@inline function _axis_selector(axis, x::Integer)
    return x:x
end

@inline function _axis_selector(axis, x::Number)
    indices = findall(axis_value -> isapprox(axis_value, x), axis)
    isempty(indices) && throw(BoundsError(axis, x))
    length(indices) == 1 ||
        throw(ArgumentError("multiple axis coordinates are approximately equal to $x"))
    return only(indices):only(indices)
end

@inline function _axis_selector(axis, x)
    return x
end

@inline function _axis_selectors(axes, I...)
    return ntuple(
        index -> index <= length(I) ? _axis_selector(axes[index], I[index]) : Colon(),
        length(axes)
    )
end

@inline function _axis_selector_kwargs(names, axes, kwargs)
    axis_by_name = Dict(zip(names, axes))
    return (; (key => _axis_selector(axis_by_name[key], value) for
               (key, value) in kwargs)...)
end

@inline function _axes_match(a::AbstractSuperposition, b::AbstractSuperposition)
    return ((a.axis1 ≈ b.axis1) && (a.axis2 ≈ b.axis2))
end

@inline function _axes_match(
    a::AbstractSuperposition1D,
    b::AbstractSuperposition1D
)
    return (a.axis ≈ b.axis)
end

@inline _typewrapper(::Type{T}) where {T} = Base.typename(T).wrapper

@inline function rebuild_superposition(
    x::AbstractSuperposition,
    data::AbstractMatrix,
    axis1::AbstractVector,
    axis2::AbstractVector
)
    return _typewrapper(typeof(x))(data, axis1, axis2)
end

@inline function rebuild_superposition(
    x::AbstractSuperposition1D,
    data::AbstractVector,
    axis::AbstractVector
)
    return _typewrapper(typeof(x))(data, axis)
end

@inline function rebuild_superposition(x::AbstractSuperposition, selection::AxisArray)
    axis1, axis2 = AxisArrays.axisvalues(selection)
    return rebuild_superposition(x, selection.data, axis1, axis2)
end

@inline function rebuild_superposition(x::AbstractSuperposition1D, selection::AxisArray)
    axis = only(AxisArrays.axisvalues(selection))
    return rebuild_superposition(x, selection.data, axis)
end

@inline function _find_first_in_broadcast(args, ::Type{T}) where {T}
    for arg in args
        if arg isa T
            return arg
        elseif arg isa Broadcast.Broadcasted
            sp = _find_first_in_broadcast(arg.args, T)
            sp === nothing || return sp
        end
    end
    return nothing
end

@inline function _check_axes_in_broadcast(
    args,
    sp::Union{AbstractSuperposition,AbstractSuperposition1D}
)
    type = (typeof(sp) <: AbstractSuperposition) ?
           AbstractSuperposition :
           AbstractSuperposition1D
    typename = (typeof(sp) <: AbstractSuperposition) ?
               "AbstractSuperposition axes" :
               "AbstractSuperposition1D axis"
    for arg in args
        if arg isa type
            arg === sp && continue
            _axes_match(sp, arg) || throw(DimensionMismatch(
                "$(typename) must match for broadcasting."
            ))
        elseif arg isa Broadcast.Broadcasted
            _check_axes_in_broadcast(arg.args, sp)
        end
    end
    return nothing
end

function _convert_to_range(x::AbstractVector)
    (length(x) == 0) && return nothing
    (length(x) == 1) && return (x:x)
    start_val = x[begin]
    end_val = x[end]
    step_val = x[2] - x[1]
    return range(start_val, stop=end_val, step=step_val)
end
