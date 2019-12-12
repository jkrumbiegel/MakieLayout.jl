using Makie
using MakieLayout


function grid!(content::Vararg{Pair}; kwargs...)
    g = GridLayout(; kwargs...)
    for ((rows, cols), element) in content
        g[rows, cols] = element
    end
    g
end

function hbox!(content::Vararg; kwargs...)
    ncols = length(content)
    g = GridLayout(1, ncols; kwargs...)
    for (i, element) in enumerate(content)
        g[1, i] = element
    end
    g
end

function vbox!(content::Vararg; kwargs...)
    nrows = length(content)
    g = GridLayout(nrows, 1; kwargs...)
    for (i, element) in enumerate(content)
        g[i, 1] = element
    end
    g
end

function grid!(scene::Scene, padding::Real, args...; kwargs...)
    grid!(args...; parent = scene, alignmode = Outside(padding), kwargs...)
end

function hbox!(scene::Scene, padding::Real, args...; kwargs...)
    hbox!(args...; parent = scene, alignmode = Outside(padding), kwargs...)
end

function vbox!(scene::Scene, padding::Real, args...; kwargs...)
    vbox!(args...; parent = scene, alignmode = Outside(padding), kwargs...)
end

function grid!(content::AbstractMatrix; kwargs...)
    nrows, ncols = size(content)
    g = GridLayout(nrows, ncols; kwargs...)
    for i in 1:nrows, j in 1:ncols
        g[i, j] = content[i, j]
    end
    g
end

begin
    scene = Scene(camera = campixel!)
    display(scene)
    ax = LAxis(scene)
    ax2 = LAxis(scene)
    cb = LColorbar(scene, width=50, height = Relative(0.5))
    lg = LLegend(scene)
    buttons = [LButton(scene; height=Auto()) for i in 1:3, j in 1:3]
    buttons2 = [LButton(scene; height=Auto()) for i in 1:3, j in 1:3]

    g = vbox!(scene, 30,
            hbox!(
                grid!(
                    [1, 1] => ax,
                    [2, 1:2] => ax2,
                    [1, 2] => grid!(buttons2)
                ),
                cb,
                lg;
                addedcolgaps = Fixed(50)),
            grid!([
                LText(scene, "Slider")    LSlider(scene);
                LText(scene, "Slider 2")  LSlider(scene);
                LText(scene, "Slider 3")  LSlider(scene)
            ]),
            grid!(buttons))
end
