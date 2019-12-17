using MakieLayout
using Makie
using Colors

begin
    scene = Scene(camera = campixel!)
    display(scene)

    g = GridLayout(scene, alignmode=Outside(30))

    rowsize!(g, 1, Auto(false))
    colsize!(g, 1, Auto(false))
    ax = g[1, 1] = LAxis(scene)

    nlines = 10
    xs = 1:0.1:10
    linearr = [lines!(ax, xs, sin.(xs .+ i/3) .* 5, color = col, linestyle = :dash)
        for (i, col) in enumerate(LCHuv.(50, 80, LinRange(0, 360, nlines + 1)[1:end-1]))]

    xs2 = 1:0.5:10
    scatarr = [scatter!(ax, xs2, sin.(xs2 .+ i/3) .* 5, color = col, strokewidth=5, marker = rand(('◀', '■', :circle, :cross, :x)))
        for (i, col) in enumerate(LCHuv.(50, 80, LinRange(0, 360, nlines + 1)[1:end-1]))]


    ll = g[1, 2] = LLegend(scene)

    sg = g[2, :] = GridLayout()

    sg[1, 1] = LText(scene, "Columns", halign=:left)
    colslider = sg[1, 2] = LSlider(scene, range=1:5, height=30)
    on(colslider.value) do v; ll.ncols = v; end;

    sg[2, 1] = LText(scene, "Patch Width", halign=:left)
    patchslider_h = sg[2, 2] = LSlider(scene, range=10:80, height=30)
    on(patchslider_h.value) do v; ll.patchsize = Base.setindex(ll.patchsize[], v, 1); end;

    sg[3, 1] = LText(scene, "Patch Height", halign=:left)
    patchslider_v = sg[3, 2] = LSlider(scene, range=10:80, height=30)
    on(patchslider_v.value) do v; ll.patchsize = Base.setindex(ll.patchsize[], v, 2); end;

    bg = sg[4, :] = GridLayout()
    addbutton = bg[1, 1] = LButton(scene, label = "Add legend entry",
        height = Auto())
    delbutton = bg[1, 2] = LButton(scene, label = "Remove legend entry",
        height = Auto())

    on(addbutton.clicks) do c
        i_randline = rand(1:length(linearr))
        ll.entries[] = [
            ll.entries[];
            LegendEntry("Line $i_randline", linearr[i_randline], scatarr[i_randline])
        ]
    end
    on(delbutton.clicks) do c
        ll.entries[] = ll.entries[][1:end-1];
    end

    nothing
end

g[1, 2] = ll
lg = gridnest!(g, 1, 2)
ll2 = lg[2, 1] = LLegend(scene)
ll2.valign = :top

rowsize!(lg, 1, Auto(true))

ll2.entries[] = LegendEntry.(["Size $i" for i in 1:5:30], [MarkerElement(color = :black, markersize = i, marker = '⚫', strokecolor = :transparent) for i in 1:5:30])


ll.entries[] = [ll.entries[];
    MakieLayout.LegendEntry(
        MakieLayout.LegendElement[
            MakieLayout.LineElement(; color = :green, linestyle = :dot)], Attributes(label = "Blibli"))]

ll.title = "Long\ntitle"
ll.entries[] = LegendEntry.(["Line $i" for i in 1:length(linearr)], linearr, scatarr)

linearr[1].color = :black
ll.bgcolor = :gray
ll.halign = :left
ll.valign = :top
ll.margin = (10, 10, 10, 10)

ll.strokecolor = :transparent
ll.patchcolor = :white
ll.titlesize = 24
ll.entries[][1].labelsize = 20
ll.entries[][1].labelcolor = :red
ll.labelcolor = :black
ll.entries[][1].label = "whoopdeedoo"
ll.labelsize = 18
ll.patchsize = (40, 40)
ll.labelhalign = :left
ll.labelvalign = :center
ll.patchlabelgap = 5
ll.rowgap = 5
ll.colgap = 10
ll.markerpoints = Point2f0.([0.2, 0.5, 0.8], [0.2, 0.5, 0.8])
ll.linepoints = [Point2f0(0, 0), Point2f0(1, 1)]
ll.entries[][1].linepoints = Point2f0.(LinRange(0, 1, 40), sin.(LinRange(0, 2pi, 40)) .* 0.5 .+ 0.5)

ll.entries[] = reverse(ll.entries[])
using Random
ll.entries[] = shuffle!(ll.entries[])
ll.entries[] = ll.entries[][1:end-1]; display(scene);
scene
ll.patchsize = 60
ll.halign = rand(setdiff([:left, :center, :right], [ll.halign[]]))
ll.valign = rand(setdiff([:bottom, :center, :top], [ll.valign[]]))
ll.margin = rand(4) .* 0

translate!(ll.scene, 0, 0, 10)

linearr[2].color = :red
scatarr[2].color = :red
scatarr[2].marker = 'm'

@macroexpand @lift($nodes[1])
