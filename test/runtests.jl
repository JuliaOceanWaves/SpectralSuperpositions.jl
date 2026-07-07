using Test, SafeTestsets

@time @testset verbose = true "RepoTemplate.jl" begin
    @time @safetestset "Main Tests" begin
        include("test_main.jl")
    end
    @time @safetestset "Doc Tests" begin
        include("test_doctest.jl")
    end
end
