using AxisArrays
using DimensionfulAngles.DefaultSymbols
using SpectralSuperpositions
using Test
using Unitful: Hz, m

struct TestSuperposition1D{TDAT, TAX <: AbstractVector} <:
       AbstractSuperposition1D{TDAT}
    data::Vector{TDAT}
    axis::TAX
    axistype::Symbol
    axisname::Symbol

    function TestSuperposition1D(data::AbstractVector, axis::AbstractVector)
        validated = validate_superposition1d(data, axis)
        return new{eltype(validated.data), typeof(validated.axis)}(
            validated.data,
            validated.axis,
            validated.axistype,
            validated.axisname
        )
    end
end

struct TestSuperposition{
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

    function TestSuperposition(data::AbstractMatrix, axis1::AbstractVector,
            axis2::AbstractVector)
        validated = validate_superposition(data, axis1, axis2)
        return new{eltype(validated.data), typeof(validated.axis1),
            typeof(validated.axis2)}(
            validated.data,
            validated.axis1,
            validated.axis2,
            validated.coordinates,
            validated.axestypes,
            validated.axesnames
        )
    end
end

TestSuperposition1D(x::AxisArray) = TestSuperposition1D(x.data, only(axisvalues(x)))
TestSuperposition(x::AxisArray) = TestSuperposition(x.data, axisvalues(x)...)

@testset "AbstractSuperposition1D" begin
    f = [3, 2, 1] .* Hz
    data = [3, 2, 1] .* (m^2 / Hz)
    x = TestSuperposition1D(data, f)

    @test x.axis == reverse(f)
    @test x.data == reverse(data)
    @test axestypes(x) == :frequency
    @test axesnames(x) == :frequency
    @test axesinfo(x) == axesinfo(:frequency)
    @test istemporal(x.axis)
    @test isevenlyspaced(x)
    @test evenspacing(x)[2] ≈ 1Hz
    @test unit(x, :integral) == m^2
    @test x[frequency = 2] isa AxisArray
    @test TestSuperposition1D(AxisArray(x)) == x
    @test copy(x) == x
    @test similar(x, Float64, size(x)) isa TestSuperposition1D
    @test (x .+ x) == TestSuperposition1D(2 .* x.data, x.axis)
    @test_throws DimensionMismatch x .+ TestSuperposition1D(x.data, x.axis .+ 0.1Hz)
    @test_throws ArgumentError TestSuperposition1D([1, 2] .* m, [0, 1] .* Hz)
    @test_throws ArgumentError TestSuperposition1D([1, 2] .* m, [1, 2] .* °)
end

@testset "AbstractSuperposition" begin
    f = [1, 2] .* Hz
    θ = [0, 90] .* °
    data = reshape(1:4, 2, 2) .* (m^2 / Hz / °)
    x = TestSuperposition(data, f, θ)

    @test ispolar(x)
    @test !iscartesian(x)
    @test coordinates(x) == :polar
    @test axestypes(x) == (:frequency, :direction)
    @test axesnames(x) == (:frequency, :direction)
    @test unit(x, :integral) == m^2
    @test x[1, 1] == data[1, 1]
    @test x[frequency = 1, direction = 2] isa TestSuperposition
    @test TestSuperposition(AxisArray(x)) == x
    @test similar(x, Float64, size(x)) isa TestSuperposition
    @test (x .+ x) == TestSuperposition(2 .* data, f, θ)

    direction_first = TestSuperposition(reshape(1:2, 1, 2), [0] .* °, f)
    @test ispolar(direction_first)
    @test size(direction_first) == (2, 1)
    @test direction_first.axis1 == f
    @test direction_first.axis2 == [0] .* °
    @test direction_first.data == reshape(1:2, 2, 1)

    kx = [-1, 1] .* (rad / m)
    ky = [-2, 0, 2] .* (rad / m)
    y = TestSuperposition(ones(2, 3), kx, ky)
    @test iscartesian(y)
    @test axesnames(y) == (:angular_wavenumber_1, :angular_wavenumber_2)
    @test_throws ArgumentError TestSuperposition(ones(2, 2), [1, 2] .* °,
        [3, 4] .* °)
end
