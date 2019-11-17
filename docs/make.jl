using Documenter, MakieLayout, Makie

makedocs(
    sitename="MakieLayout.jl",
    format = Documenter.HTML(
            prettyurls = get(ENV, "CI", nothing) == "true"
        )
    )

# deploydocs(
#     repo = "github.com/jkrumbiegel/Animations.jl.git",
# )
