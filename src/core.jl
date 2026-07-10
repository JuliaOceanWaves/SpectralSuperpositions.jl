"""
Abstract type for creating 2-D spectra structs. The types and arguments have been defined as
well as a validate_superposition function to ensure consistency.
"""
abstract type AbstractSuperposition{TDAT} <: AbstractMatrix{TDAT} end
"""
Abstract type for creating 2-D spectra structs. The types and arguments have been defined as
well as a validate_superposition function to ensure consistency.
"""
abstract type AbstractSuperposition1D{TDAT} <: AbstractVector{TDAT} end

include("core/superposition1d.jl")
include("core/superposition.jl")
