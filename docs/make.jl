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

struct Gitlab <: Documenter.DeployConfig end

function Documenter.deploy_folder(cfg::Gitlab;
        repo, devbranch, push_preview, devurl, kwargs...)

    folder = devurl
end

Documenter.authentication_method(::Gitlab) = Documenter.SSH

println("ENV[DOCUMENTER_KEY] working?", typeof(Documenter.documenter_key(Gitlab())), length(Documenter.documenter_key(Gitlab())))

deploydocs(
    repo = "github.com/jkrumbiegel/MakieLayout.jl.git",
    deploy_config = Gitlab(),
)
