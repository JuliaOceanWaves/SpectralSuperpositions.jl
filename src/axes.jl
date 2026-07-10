# Axes utilities for SpectralSuperpositions

AxisArrays.axes(x::AbstractSuperposition) = (x.axis1, x.axis2)
AxisArrays.axes(x::AbstractSuperposition1D) = (x.axis,)
AxisArrays.axisvalues(x::AbstractSuperposition) = AxisArrays.axes(x)
AxisArrays.axisvalues(x::AbstractSuperposition1D) = AxisArrays.axes(x)

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

"""
    axesinfo()
    axesinfo(s::Symbol)
    axesinfo(x)

Query the axis type and its physical dimensions.

There are 8 supported spectral-variable types, formed from the combinations of
spatial/temporal domain, linear/angular geometry, and frequency/period quantity.
There's one direction type `:direction`, for a total of 9 possible axis types.

- `axesinfo()` returns a dictionary with information for all 9 possible axis types.
- `axesinfo(s::Symbol)` returns information for a specific axis type, e.g.
  `axesinfo(:wavenumber)`
- `axesinfo(x)` return the axis information for the axes of a spectrum x.

The dictionary is as follows:

    :direction          => ((:direction,), 𝐀),
    :frequency          => ((:temporal, :linear, :frequency), 𝐓^-1),
    :angular_frequency  => ((:temporal, :angular, :frequency), 𝐀 * 𝐓^-1),
    :period             => ((:temporal, :linear, :period), 𝐓),
    :angular_period     => ((:temporal, :angular, :period), 𝐓 * 𝐀^-1),
    :wavenumber         => ((:spatial, :linear, :frequency), 𝐋^-1),
    :angular_wavenumber => ((:spatial, :angular, :frequency), 𝐀 * 𝐋^-1),
    :wavelength         => ((:spatial, :linear, :period), 𝐋),
    :angular_wavelength => ((:spatial, :angular, :period), 𝐋 * 𝐀^-1)
"""
function axesinfo end
axesinfo() = _AXESINFO
axesinfo(s::Symbol) = axesinfo()[s]
axesinfo(x) = axesinfo.(axestypes(x))

"""
    axestypes(x::Quantity)
    axestypes(x::Units)
    axestypes(x::AbstractVector{<:Quantity})
    axestypes(x::AbstractSuperposition)
    axestypes(x::AbstractSuperposition1D)
    axestypes(dim::Dimensions)

Returns the type of axes as a symbol based on the unitful dimension. Uses the following 
dictionary.

    Dict{Unitful.Dimensions, Symbol} with 9 entries:
    𝐋⁻¹   => :wavenumber
    𝐀 𝐋⁻¹ => :angular_wavenumber
    𝐓⁻¹   => :frequency
    𝐀     => :direction
    𝐀 𝐓⁻¹ => :angular_frequency
    𝐋     => :wavelength
    𝐓     => :period
    𝐓 𝐀⁻¹ => :angular_period
    𝐋 𝐀⁻¹ => :angular_wavelength

"""
function axestypes end
axestypes(x::Quantity) = axestypes(dimension(x))
axestypes(x::Units) = axestypes(dimension(x))
axestypes(x::AbstractVector{<:Quantity}) = axestypes(dimension(eltype(x)))
axestypes(x::AbstractSuperposition) = x.axestypes
axestypes(x::AbstractSuperposition1D) = x.axistype

axestypes(dim::Dimensions) = _AXESTYPES_BY_DIM[dim]

function axestypes(domain::Symbol, geometry::Symbol, quantity::Symbol)
    _AXESTYPES_BY_INFO[(domain, geometry, quantity)]
end


# Generic axes properties. Can be used on Unitful numbers, units, or axes of 
# AbstractSuperposition[1D]. 
"""
    istemporal(x)

Returns true if the unit dimensions are :temporal.

See also [`axesinfo()`](@ref)
"""
function istemporal(x)
    axesinfo()[axestypes(x)][1][1] == :temporal
end

"""
    isspatial(x)

Returns true if the unit dimensions are :spatial. 
"""
function isspatial(x)
    axesinfo()[axestypes(x)][1][1] == :spatial
end

"""
    islinear(x)

Returns true if the unit dimensions are :linear. 
"""
function islinear(x)
    axesinfo()[axestypes(x)][1][2] == :linear
end

"""
    isangular(x)

Returns true if the unit dimensions are :angular. 
"""
function isangular(x)
    axesinfo()[axestypes(x)][1][2] == :angular
end

"""
    isfrequency(x)

Returns true if the unit dimensions are :frequency. 
"""
function isfrequency(x)
    axesinfo()[axestypes(x)][1][3] == :frequency
end

"""
    isperiod(x)

Returns true if the unit dimensions are :period. 
"""
function isperiod(x)
    axesinfo()[axestypes(x)][1][3] == :period
end

"""
    isdirection(x)

Returns true if the unit dimensions are a :direction. 
"""
function isdirection(x)
    axesinfo()[axestypes(x)][1][1] == :direction
end

"""
    isspectralvariable(x)

Returns true if the unit dimensions are not a direction and some other spectral variable 
instead. 
"""
function isspectralvariable(x)
    !isdirection(x)
end

"""
    istemporal(x::AbstractSuperposition)

Returns true if the first axis of AbstractSuperposition has unit dimensions that are 
:temporal. 
"""
istemporal(x::AbstractSuperposition) = istemporal(x.axis1)

"""
    isspatial(x::AbstractSuperposition)

Returns true if the first axis of AbstractSuperposition has unit dimensions that are 
:spatial. 
"""
isspatial(x::AbstractSuperposition) = isspatial(x.axis1)

"""
    ispolar(x::AbstractSuperposition)

Returns true if the Spectrum is in :polar coordinates. 
"""
function ispolar(x::AbstractSuperposition)
    x.coordinates == :polar
end

"""
    iscartesian(x::AbstractSuperposition)

Returns true if the Spectrum is in :cartesian coordinates. 
"""
function iscartesian(x::AbstractSuperposition)
    x.coordinates == :cartesian
end

"""
    coordinates(x::AbstractSuperposition)

Returns a symbol whether the Spectrum is in :polar or :cartesian coordinates. 
"""
function coordinates(x::AbstractSuperposition)
    x.coordinates
end

"""
    axesnames(x::AbstractSuperposition)
    axesnames(x::AbstractSuperposition1D)

Return the axes names for an AbstractSuperposition or the axis name for an 
AbstractSuperposition1D
"""
function axesnames end

function axesnames(x::AbstractSuperposition)
    x.axesnames
end

function axesnames(x::AbstractSuperposition1D)
    x.axisname
end

"""
    isevenlyspaced(x::AbstractVector)
    isevenlyspaced(x::AbstractSuperposition)
    isevenlyspaced(x::AbstractSuperposition1D)

Return true if the axis values are evenly spaced.
"""
function isevenlyspaced end

function isevenlyspaced(x::AbstractVector)
    x_range = _convert_to_range(x)
    return ((length(x) == length(x_range)) && isapprox(x, x_range))
end
isevenlyspaced(x::AbstractSuperposition) = (isevenlyspaced(x.axis1) && isevenlyspaced(x.axis2))
isevenlyspaced(x::AbstractSuperposition1D) = isevenlyspaced(x.axis)

"""
    evenspacing(x::AbstractVector)
    evenspacing(x::AbstractSuperposition)
    evenspacing(x::AbstractSuperposition1D)

Return evenly spaced axis parameters as tuples `(start, step, length)`.

For a Spectrum two such tuples are returned, one for each axis.
Throws `ArgumentError` if the axis or axes are not evenly spaced.
"""
function evenspacing end

function evenspacing(x::AbstractVector)
    isevenlyspaced(x) || throw(ArgumentError("Vector `x` must be evenly spaced."))
    r = _convert_to_range(x)
    return (first(r), step(r), length(r))
end

evenspacing(x::AbstractSuperposition) = (evenspacing(x.axis1), evenspacing(x.axis2))

evenspacing(x::AbstractSuperposition1D) = evenspacing(x.axis)
