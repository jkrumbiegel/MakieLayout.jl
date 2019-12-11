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
    linearr = [lines!(ax, xs, sin.(xs .+ i/3), color = col)
        for (i, col) in enumerate(LCHuv.(50, 80, LinRange(0, 360, nlines + 1)[1:end-1]))]

    xs2 = 1:0.5:10
    scatarr = [scatter!(ax, xs2, sin.(xs2 .+ i/3), color = col, marker = rand(('◀', '■', :circle, :cross, :x)))
        for (i, col) in enumerate(LCHuv.(50, 80, LinRange(0, 360, nlines + 1)[1:end-1]))]


    ll = g[1, 2] = LLegend(scene, halign=:left, valign=:top)

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
            LegendEntry("Line $i_randline", AbstractPlot[linearr[i_randline], scatarr[i_randline]])
        ]
    end
    on(delbutton.clicks) do c
        ll.entries[] = ll.entries[][1:end-1];
    end

    nothing
end

ll.entries[][1].attributes.labelsize = 30
ll.labelsize = 40
ll.labelhalign = :left
ll.labelvalign = :center
ll.patchlabelgap = 5
ll.rowgap = 10
ll.valign = :center
ll.margin = (10, 10, 10, 10)

ll.entries[] = reverse(ll.entries[])
using Random
ll.entries[] = shuffle!(ll.entries[])
ll.entries[] = ll.entries[][1:end-1]; display(scene);
scene
ll.patchsize = 60
ll.halign = rand(setdiff([:left, :center, :right], [ll.halign[]]))
ll.valign = rand(setdiff([:bottom, :center, :top], [ll.valign[]]))
ll.margin = rand(4) .* 40

translate!(ll.scene, 0, 0, 10)
