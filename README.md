# SpectralSuperpositions.jl

[![Test](https://github.com/JuliaOceanWaves/SpectralSuperpositions.jl/actions/workflows/Test.yml/badge.svg)](https://github.com/JuliaOceanWaves/SpectralSuperpositions.jl/actions/workflows/Test.yml)
[![Coverage](https://codecov.io/gh/JuliaOceanWaves/SpectralSuperpositions.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaOceanWaves/SpectralSuperpositions.jl)
[![deps](https://platform.juliahub.com/docs/General/SpectralSuperpositions/stable/deps.svg)](https://platform.juliahub.com/ui/Packages/General/SpectralSuperpositions?t=2)

A library of components to use as a foundation for constructing and validating one-dimensional frequency spectra and two-dimensional spatial/polar spectra.

A collection of structs and utilities for building other packages that work with spectral representations. 
It defines the abstract types for both cases and includes a set of helper functions to validate and classify the axes and data, ensure consistency, and validate spectral variables. 
Examples include [WaveRealizations.jl](https://github.com/JuliaOceanWaves/WaveRealizations.jl) and [WaveSpectra.jl](https://github.com/JuliaOceanWaves/WaveSpectra.jl) which include workflows for spectral modeling and analysis. 

## Basic Usage

WaveRealizations.jl `ComplexAmplitudes` constructor that uses SpectralSuperpositions.jl abstract type and validation function to ensure consistency. 

```julia-repl
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

## Development

```julia
using Pkg
Pkg.test("SpectralSuperpositions")
```

## Contributing

Contributions are welcome! 🎊 Please see the [contribution guidelines](https://github.com/JuliaOceanWaves/.github/blob/main/CONTRIBUTING.md) for ways to contribute to the project.

## License

MIT. See `LICENSE`.