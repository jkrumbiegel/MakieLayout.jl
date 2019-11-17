using Documenter, MakieLayout, Makie

makedocs(
    sitename="MakieLayout.jl",
    pages = [
        "index.md",
        "Grids" => "grids.md",
        "LayoutedAxis" => "layoutedaxis.md",
    ],
    format = Documenter.HTML(
            prettyurls = get(ENV, "CI", nothing) == "true"
        )
    )

# deploydocs(
#     repo = "github.com/jkrumbiegel/Animations.jl.git",
# )
