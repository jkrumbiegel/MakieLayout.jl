using Documenter, MakieLayout, Makie, Animations, ColorSchemes, Colors

# don't open windows while generating animations
Makie.AbstractPlotting.inline!(true)

makedocs(
    sitename="MakieLayout.jl",
    pages = [
        "index.md",
        "GridLayout" => "grids.md",
        "LAxis" => "laxis.md",
        "How layouting works" => "layouting.md",
        "Frequently Asked Questions" => "faq.md",
    ],
    format = Documenter.HTML(
            prettyurls = get(ENV, "CI", nothing) == "true"
        )
    )

struct Local <: Documenter.DeployConfig end

function Documenter.deploy_folder(cfg::Local;
        repo, devbranch, push_preview, devurl, kwargs...)

    folder = if ENV["PUSH_LOCAL_BUILD"] == "true"
        @warn("Setting ENV[\"PUSH_LOCAL_BUILD\"] = \"false\", remember to set it to true for the next push.")
        ENV["PUSH_LOCAL_BUILD"] = "false"
        devurl
    else
        @warn("Set ENV[\"PUSH_LOCAL_BUILD\"] = \"true\" if you want your local build to be pushed to Github Pages.")
        nothing
    end
end

Documenter.authentication_method(::Local) = Documenter.SSH

function Documenter.documenter_key(::Local)
    open(readline, expanduser("~/.ssh/documenter_makielayout"))
end

deploydocs(
    repo = "github.com/jkrumbiegel/MakieLayout.jl.git",
    deploy_config = Local(),
)
