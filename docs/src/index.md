# SpectralSuperpositions.jl

Short documentation for the SpectralSuperpositions.jl package.

## Quick Start

This packages is meant to be used as a foundation for other frequency spectra packages.
Below is an example from `WaveRealizations.jl`.

```julia
using SpectralSuperpositions

struct ComplexAmplitudes{
    TDAT,
    TAX1 <: AbstractVector,
    TAX2 <: AbstractVector
} <: AbstractSuperposition{TDAT}
    data::Matrix{TDAT}
    axis1::TAX1
    axis2::TAX2
    coordinates::Symbol
    axestypes::Tuple{Symbol, Symbol}
    axesnames::Tuple{Symbol, Symbol}

    function ComplexAmplitudes(
            data::AbstractMatrix,
            axis1::AbstractVector,
            axis2::AbstractVector
    )
        validated = validate_superposition(data, axis1, axis2)


        return new{
            eltype(validated.data), typeof(validated.axis1), typeof(validated.axis2)}(
            validated.data,
            validated.axis1,
            validated.axis2,
            validated.coordinates,
            validated.axestypes,
            validated.axesnames
        )
    end
end
```
