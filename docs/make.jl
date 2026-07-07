using Documenter
using RepoTemplate

DocMeta.setdocmeta!(RepoTemplate, :DocTestSetup, :(using RepoTemplate); recursive = true)
#bib = CitationBibliography(joinpath(@__DIR__, "references.bib"))

makedocs(
    sitename = "RepoTemplate.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        assets = String["src/index.css"]
    ),
    modules = [RepoTemplate],
    pages = ["Home" => "index.md"]    #plugins = [bib],
)

deploydocs(
    repo = "github.com/JuliaOceanWaves/RepoTemplate.jl.git",
    devbranch = "main",
    push_preview = true
)
