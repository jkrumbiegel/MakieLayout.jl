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
        "LLegend" => "llegend.md",
    ],
    format = Documenter.HTML(
            prettyurls = get(ENV, "CI", nothing) == "true"
        )
    )

# struct Local <: Documenter.DeployConfig end
#
# function Documenter.deploy_folder(cfg::Local;
#         repo, devbranch, push_preview, devurl, kwargs...)
#
#     folder = if get(ENV, "PUSH_LOCAL_BUILD", false) == "true"
#         @warn("Setting ENV[\"PUSH_LOCAL_BUILD\"] = \"false\", remember to set it to true for the next push.")
#         ENV["PUSH_LOCAL_BUILD"] = "false"
#         devurl
#     else
#         @warn("Set ENV[\"PUSH_LOCAL_BUILD\"] = \"true\" if you want your local build to be pushed to Github Pages.")
#         nothing
#     end
# end
#
# Documenter.authentication_method(::Local) = Documenter.SSH
#
# function Documenter.documenter_key(::Local)
#     open(readline, expanduser("~/.ssh/documenter_makielayout"))
# end


struct Gitlab <: Documenter.DeployConfig
    commit_branch::String
    pull_request_iid::String
    repo_slug::String
    commit_tag::String
    pipeline_source::String
end

function Gitlab()
    commit_branch = get(ENV, "CI_COMMIT_BRANCH", "")
    pull_request_iid = get(ENV, "CI_EXTERNAL_PULL_REQUEST_IID", "")
    repo_slug = get(ENV, "CI_PROJECT_PATH_SLUG")
    commit_tag = get(ENV, "CI_COMMIT_TAG", "")
    pipeline_source = get(ENV, "CI_PIPELINE_SOURCE", "")
    Gitlab(
        commit_branch,
        pull_request_iid,
        repo_slug,
        commit_tag,
        pipeline_source,
    )
end

function Documenter.deploy_folder(cfg::Gitlab; repo, devbranch, push_preview, devurl, kwargs...)

    io = IOBuffer()
    all_ok = true

    println(io, "Gitlab config:\n", cfg)

    subfolder = if cfg.commit_tag != ""
        tag_ok = occursin(Base.VERSION_REGEX, cfg.commit_tag)
        println("tag_ok: ", tag_ok)
        all_ok &= tag_ok

        cfg.travis_tag
    else
        devurl
    end


    key_ok = haskey(ENV, "DOCUMENTER_KEY")
    println(io, "key_ok: ", key_ok)
    all_ok &= key_ok

    @info String(take!(io))

    return all_ok ? subfolder : nothing
end


deploydocs(
    repo = "github.com/jkrumbiegel/MakieLayout.jl.git",
    deploy_config = Gitlab(),
)
