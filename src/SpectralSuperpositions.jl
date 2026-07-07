module SpectralSuperpositions

using Unitful: Quantity, Units, Dimensions, NoUnits, dimension
using DimensionfulAngles: 𝐀, 𝐋, 𝐓
using AxisArrays: Axis, axisvalues, ClosedInterval, (..)

import Base: copy, eltype, getindex, setindex!, show, similar, size, (==), (!=), (<), (<=),
    (>), (>=)
import Unitful: uconvert, unit
import AxisArrays: AxisArrays, AxisArray # axes # in the future, do `import AxisArrays: axes as AAaxes`
const axes = Base.axes # name conflict will be fixed by AxisArrays in the future

export AbstractSuperposition1D, AbstractSuperposition,
    axesinfo, axesnames, axestypes, coordinates, isangular, iscartesian, isdirection,
    isfrequency, islinear, isperiod, ispolar, isspatial, isspectralvariable, istemporal,
    isevenlyspaced, evenspacing, rebuild_superposition, superposition_unit_aliases, unit,
    validate_superposition, validate_superposition1d

include("core.jl")
include("utilities.jl")
include("show.jl")
include("axes.jl")

end
