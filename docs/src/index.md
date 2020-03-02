# MakieLayout.jl

MakieLayout.jl brings a new 2D Axis `LAxis` and grid layouting with `GridLayout` to Makie.jl. You
can build complex layouts by nesting GridLayouts. You can specify many visual parameters
like row and column widths, the gap sizes
between the rows and columns, or paddings. 2D axes have many more parameters like
titles, labels, ticks, their sizes and colors and alignments, etc. All of these
parameters are Observables and the layout updates itself automatically when you
change relevant ones.

As a starting point, here's an example how you can iteratively build a plot out
of its parts:


```@example

using MakieLayout
using Makie
using Random # hide
using AbstractPlotting: px
Random.seed!(2) # hide

# layoutscene is a convenience function that creates a Scene and a GridLayout
# that are already connected correctly and with Outside alignment
scene, layout = layoutscene(30, resolution = (1200, 900),
    backgroundcolor = RGBf0(0.98, 0.98, 0.98))

record(scene, "example_plot_buildup.mp4", framerate=1) do io
    frame() = recordframe!(io) # hide
    ax1 = layout[1, 1] = LAxis(scene, title = "Group 1")
    frame() # hide
    ax2 = layout[1, 2] = LAxis(scene, title = "Group 2")
    frame() # hide
    sca1 = scatter!(ax1, randn(100, 2), markersize = 10px, color = :red)
    frame() # hide
    sca2 = scatter!(ax1, randn(100, 2) .+ 1, markersize = 10px, marker = 'x',
        color = :blue)
    frame() # hide
    sca3 = scatter!(ax2, randn(100, 2) .+ 2, markersize = 10px, marker = '□',
        color = :green)
    frame() # hide
    sca4 = scatter!(ax2, randn(100, 2) .+ 3, markersize = 10px, color = :orange)
    frame() # hide

    linkaxes!(ax1, ax2)
    autolimits!(ax1)
    frame() # hide

    leg = LLegend(scene, [sca1, sca2, sca3, sca4], ["alpha", "beta", "gamma", "delta"],
        orientation = :horizontal, height = Auto(true), width = Auto(false))
    layout[2, :] = leg
    frame() # hide

    ax3 = layout[:, end + 1] = LAxis(scene)
    frame() # hide

    ts = 0:0.01:20
    cmap = Node(:viridis)
    spiral = lines!(ax3, sin.(ts) .* ts, ts, color = ts, colormap = cmap,
        linewidth = 4)
    frame() # hide

    ax3.xlabel = "Horizontal"
    frame() # hide
    ax3.ylabel = "Vertical"
    frame() # hide

    cbar = layout[:, end + 1] = LColorbar(scene, spiral, width = 30)
    frame() # hide
    cbar.height = Relative(0.66)
    frame() # hide

    cmap[] = :inferno
    frame() # hide

    subgrid = layout[end + 1, :] = GridLayout()
    frame() # hide

    ax4 = subgrid[1, 1] = LAxis(scene)
    frame() # hide
    heatmap!(ax4, randn(50, 30))
    frame() # hide
    tightlimits!(ax4)
    frame() # hide

    sliders = [LSlider(scene) for _ in 1:3]
    labels = [LText(scene, l, halign = :left) for l in ("Adjust", "Refresh", "Compute")]
    slidergrid = subgrid[1, 0] = grid!(hcat(labels, sliders), height = Auto(false))
    frame() # hide

    ax5 = subgrid[1, 0] = LAxis(scene)
    frame() # hide
    heatmap!(ax5, randn(50, 30), colormap = :blues)
    tightlimits!(ax5)
    frame() # hide

    colsize!(subgrid, 2, Relative(0.5))
    frame() # hide

    ax4.yaxisposition = :right
    ax4.yticklabelalign = (:left, :center)
    frame() # hide

    suptitle = layout[0, :] = LText(scene, "MakieLayout.jl")
    frame() # hide
    suptitle.textsize = 40
    frame() # hide

    foreach(tight_ticklabel_spacing!, LAxis, layout)
    frame() # hide
end

nothing # hide
```

![example plot buildup](example_plot_buildup.mp4)
