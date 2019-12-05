using Documenter, MakieLayout, Makie, Animations

makedocs(
    sitename="MakieLayout.jl",
    pages = [
        "index.md",
        "Grids" => "grids.md",
        "LAxis" => "laxis.md",
    ],
    format = Documenter.HTML(
            prettyurls = get(ENV, "CI", nothing) == "true"
        )
    )

# deploydocs(
#     repo = "github.com/jkrumbiegel/Animations.jl.git",
# )
