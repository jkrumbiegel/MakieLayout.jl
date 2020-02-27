## Creating a legend

```@example
using MakieLayout
using Makie
using AbstractPlotting: px

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)

xs = 0:0.5:10
ys = sin.(xs)
lin = lines!(ax, xs, ys, color = :blue)
sca = scatter!(ax, xs, ys, color = :red, markersize = 15px)

leg = LLegend(scene, [lin, sca], ["a line", "some dots"])
layout[1, 2] = leg

# you can add more elements using push
push!(leg, "both together", lin, sca)

save("example_legend.png", scene); nothing # hide
```

![example legend](example_legend.png)


## Multi-column legend

You can control the number of columns with the `ncols` attribute.

```@example
using MakieLayout
using Makie
using AbstractPlotting: px

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)

xs = 0:0.1:10
lins = [lines!(ax, xs, sin.(xs .+ 3v), color = RGBf0(v, 0, 1-v)) for v in 0:0.1:1]

leg = LLegend(scene, lins, string.(1:length(lins)), ncols = 3)
layout[1, 2] = leg


save("example_legend_ncols.png", scene); nothing # hide
```

![example legend ncols](example_legend_ncols.png)



## Legend inside an axis

To place a legend inside an axis you can simply add it to the same layout slot
that the axis lives in. As long as the axis is bigger than the legend you can
set the legend's height and width to `Auto(false)` and position it using the align
variables. You can use the margin keyword to keep the legend from touching the axis
spines.

```@example
using MakieLayout
using Makie

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)

xs = 0:0.1:10
lins = [lines!(ax, xs, sin.(xs .* i), color = color)
    for (i, color) in zip(1:3, [:red, :blue, :green])]

legends = [LLegend(
        scene, lins, ["Line $i" for i in 1:3],
        width = Auto(false),
        margin = (10, 10, 10, 10),
    ) for j in 1:3]

haligns = [:left, :right, :center]
valigns = [:top, :bottom, :center]

for (leg, hal, val) in zip(legends, haligns, valigns)
    layout[1, 1] = leg
    leg.title = "$hal & $val"
    leg.halign = hal
    leg.valign = val
end

save("example_legend_alignment.png", scene); nothing # hide
```

![example legend alignment](example_legend_alignment.png)


## Creating legend entries manually

Sometimes you might want to construct legend entries from scratch to have maximum
control. So far you can use `LineElement`s, `MarkerElement`s or `PolyElement`s.
Some attributes that can't have a meaningful preset and would usually be inherited
from plot objects (like color) have to be explicitly specified. Others are
inherited from the legend if they are not specified. These include marker
arrangement for `MarkerElement`s or poly shape for `PolyElement`s. You can check
the list using this function:

```@example
using MakieLayout
MakieLayout.attributenames(LegendEntry)
```


```@example
using MakieLayout
using Makie
using AbstractPlotting: px

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)

leg = layout[1, 2] = LLegend(scene)

entry1 = LegendEntry(
    "Entry 1",
    LineElement(color = :red, linestyle = nothing),
    MarkerElement(color = :blue, marker = 'x', strokecolor = :black),
)

entry2 = LegendEntry(
    "Entry 2",
    PolyElement(color = :red, strokecolor = :blue),
    LineElement(color = :black, linestyle = :dash),
)

entry3 = LegendEntry(
    "Entry 3",
    LineElement(color = :green, linestyle = nothing,
        linepoints = Point2f0[(0, 0), (0, 1), (1, 0), (1, 1)])
)

entry4 = LegendEntry(
    "Entry 4",
    MarkerElement(color = :blue, marker = 'π',
        strokecolor = :transparent,
        markerpoints = Point2f0[(0.2, 0.2), (0.5, 0.8), (0.8, 0.2)])
)

entry5 = LegendEntry(
    "Entry 5",
    PolyElement(color = :green, strokecolor = :black,
        polypoints = Point2f0[(0, 0), (1, 0), (0, 1)])
)

push!(leg, entry1)
push!(leg, entry2)
push!(leg, entry3)
push!(leg, entry4)
push!(leg, entry5)

save("example_legend_entries.png", scene); nothing # hide
```

![example legend entries](example_legend_entries.png)


## Horizontal legend

In case you want the legend entries to be listed horizontally, set the `orientation`
attribute to `:horizontal`. In this case the `ncols` attribute refers to the
number of rows instead. To keep an adjacent axis from potentially shrinking to
the width of the horizontal legend, set `width = Auto(false)` and `height = Auto(true)`
if you place the legend below or above the axis.



```@example
using MakieLayout
using Makie
using AbstractPlotting: px

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)

xs = 0:0.5:10
ys = sin.(xs)
lin = lines!(ax, xs, ys, color = :blue)
sca = scatter!(ax, xs, ys, color = :red, markersize = 15px)

leg = LLegend(scene, [lin, sca, lin], ["a line", "some dots", "line again"])
layout[1, 2] = leg

leg_horizontal = LLegend(scene, [lin, sca, lin], ["a line", "some dots", "line again"],
    orientation = :horizontal, width = Auto(false), height = Auto(true))
layout[2, 1] = leg_horizontal


save("example_legend_horizontal.png", scene); nothing # hide
```

![example legend](example_legend_horizontal.png)
