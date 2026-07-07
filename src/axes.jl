# Axes utilities for SpectralSuperpositions

AxisArrays.axes(x::AbstractSuperposition) = (x.axis1, x.axis2)
AxisArrays.axes(x::AbstractSuperposition1D) = (x.axis,)
AxisArrays.axisvalues(x::AbstractSuperposition) = AxisArrays.axes(x)
AxisArrays.axisvalues(x::AbstractSuperposition1D) = AxisArrays.axes(x)

function axesinfo end

const _AXESINFO = Dict(
    :direction => ((:direction,), 𝐀),
    :frequency => ((:temporal, :linear, :frequency), 𝐓^-1),
    :angular_frequency => ((:temporal, :angular, :frequency), 𝐀 * 𝐓^-1),
    :period => ((:temporal, :linear, :period), 𝐓),
    :angular_period => ((:temporal, :angular, :period), 𝐓 * 𝐀^-1),
    :wavenumber => ((:spatial, :linear, :frequency), 𝐋^-1),
    :angular_wavenumber => ((:spatial, :angular, :frequency), 𝐀 * 𝐋^-1),
    :wavelength => ((:spatial, :linear, :period), 𝐋),
    :angular_wavelength => ((:spatial, :angular, :period), 𝐋 * 𝐀^-1)
)

const _AXESTYPES_BY_DIM = Dict(v[2] => k for (k, v) in _AXESINFO)
const _AXESTYPES_BY_INFO = Dict(v[1] => k for (k, v) in _AXESINFO)

axesinfo() = _AXESINFO
axesinfo(s::Symbol) = axesinfo()[s]
axesinfo(x) = axesinfo.(axestypes(x))

axestypes(x::Quantity) = axestypes(dimension(x))
axestypes(x::Units) = axestypes(dimension(x))
axestypes(x::AbstractVector{<:Quantity}) = axestypes(dimension(eltype(x)))
axestypes(x::AbstractSuperposition) = x.axestypes
axestypes(x::AbstractSuperposition1D) = x.axistype

axestypes(dim::Dimensions) = _AXESTYPES_BY_DIM[dim]

function axestypes(domain::Symbol, geometry::Symbol, quantity::Symbol)
    _AXESTYPES_BY_INFO[(domain, geometry, quantity)]
end

function istemporal(x)
    axesinfo()[axestypes(x)][1][1] == :temporal
end

istemporal(x::AbstractSuperposition) = istemporal(x.axis1)

function isspatial(x)
    axesinfo()[axestypes(x)][1][1] == :spatial
end

isspatial(x::AbstractSuperposition) = isspatial(x.axis1)

function islinear(x)
    axesinfo()[axestypes(x)][1][2] == :linear
end

function isangular(x)
    axesinfo()[axestypes(x)][1][2] == :angular
end

function isfrequency(x)
    axesinfo()[axestypes(x)][1][3] == :frequency
end

function isperiod(x)
    axesinfo()[axestypes(x)][1][3] == :period
end

function isdirection(x)
    axesinfo()[axestypes(x)][1][1] == :direction
end

function isspectralvariable(x)
    !isdirection(x)
end

function ispolar(x::AbstractSuperposition)
    x.coordinates == :polar
end

function iscartesian(x::AbstractSuperposition)
    x.coordinates == :cartesian
end

function coordinates(x::AbstractSuperposition)
    x.coordinates
end

function axesnames(x::AbstractSuperposition)
    x.axesnames
end

function axesnames(x::AbstractSuperposition1D)
    x.axisname
end

function isevenlyspaced(x::AbstractVector)
    x_range = _convert_to_range(x)
    return ((length(x) == length(x_range)) && isapprox(x, x_range))
end

isevenlyspaced(x::AbstractSuperposition1D) = isevenlyspaced(x.axis)

isevenlyspaced(x::AbstractSuperposition) = (isevenlyspaced(x.axis1) && isevenlyspaced(x.axis2))

function evenspacing(x::AbstractVector)
    isevenlyspaced(x) || throw(ArgumentError("Vector `x` must be evenly spaced."))
    r = _convert_to_range(x)
    return (first(r), step(r), length(r))
end

evenspacing(x::AbstractSuperposition1D) = evenspacing(x.axis)

evenspacing(x::AbstractSuperposition) = (evenspacing(x.axis1), evenspacing(x.axis2))
