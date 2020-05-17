using Documenter, MakieLayout, CairoMakie, AbstractPlotting, Animations, ColorSchemes, Colors


CairoMakie.activate!()


makedocs(
    sitename="MakieLayout.jl",
    pages = [
        "index.md",
        "GridLayout" => "grids.md",
        "LAxis" => "laxis.md",
        "LLegend" => "llegend.md",
        "Layoutables Examples" => "layoutables_examples.md",
        "Theming Layoutables" => "theming.md",
        "How Layouting Works" => "layouting.md",
        "Frequently Asked Questions" => "faq.md",
        "API Reference" => "api_reference.md",
    ],
    format = Documenter.HTML(
            prettyurls = get(ENV, "CI", nothing) == "true"
        )
    )


deploydocs(
    repo = "github.com/jkrumbiegel/MakieLayout.jl.git",
)
