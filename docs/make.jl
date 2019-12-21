using Documenter, MakieLayout, Makie, Animations

# don't open windows while generating animations
Makie.AbstractPlotting.inline!(true)

makedocs(
    sitename="MakieLayout.jl",
    pages = [
        "index.md",
        "GridLayout" => "grids.md",
        "LAxis" => "laxis.md",
        "How layouting works" => "layouting.md"
    ],
    format = Documenter.HTML(
            prettyurls = get(ENV, "CI", nothing) == "true"
        )
    )

# deploydocs(
#     repo = "github.com/jkrumbiegel/Animations.jl.git",
# )
