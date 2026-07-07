abstract type AbstractSuperposition{TDAT} <: AbstractMatrix{TDAT} end
abstract type AbstractSuperposition1D{TDAT} <: AbstractVector{TDAT} end

include("core/superposition1d.jl")
include("core/superposition.jl")
