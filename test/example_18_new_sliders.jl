using Makie
using MakieLayout
using Printf


begin
    scene = Scene(camera=campixel!)
    screen = display(scene)

    outergrid = GridLayout(scene; alignmode=Outside(30))

    innergrid = outergrid[1, 1] = GridLayout()

    lagrid = innergrid[1, 1] = GridLayout()
    la = lagrid[1, 1] = LayoutedAxis(scene)
    # la.xoppositespinevisible = false
    # la.yoppositespinevisible = false
    la.xgridvisible = false
    la.ygridvisible = false
    la.xautolimitmargin = (0, 0)
    la.yautolimitmargin = (0, 0)



    slidergrid = innergrid[2, 1] = GridLayout()

    ls1 = slidergrid[1, 1] = LayoutedSlider(scene, range=50:0.01:100, height=50)
    slidergrid[1, 2] = LayoutedText(scene, text=lift(x->@sprintf("%.2f", x), ls1.value),
        alignment=(:right, :center), width=140, padding=(5, 5, 5, 5))
    slidergrid[1, 2] = LayoutedRect(scene, color=:white, strokewidth=2f0, strokecolor=RGBf0(0.9, 0.9, 0.9))

    ls2 = slidergrid[2, 1] = LayoutedSlider(scene, range=LinRange(0.1, 3, 1000), startvalue=1, height=50)
    slidergrid[2, 2] = LayoutedText(scene, text=lift(x->@sprintf("%.2f", x), ls2.value),
        alignment=(:right, :center), width=140, padding=(5, 5, 5, 5))
    slidergrid[2, 2] = LayoutedRect(scene, color=:white, strokewidth=2f0, strokecolor=RGBf0(0.9, 0.9, 0.9))

    ls3 = innergrid[1, end+1] = LayoutedSlider(scene, range=0:0.01:1, width=50, horizontal=false)

    buttongrid = slidergrid[3, :] = GridLayout()
    buttongrid[1, 1] = LayoutedButton(scene, height=40)
    b2 = buttongrid[1, 2] = LayoutedButton(scene, autoshrink=(false, false), label="Change colormap")

    data = lift(ls2.value, ls3.value) do v1, v2
        [sin(x * y / 1000 * v1) * v2 for x in 1:100, y in 1:100]
    end

    hmap = heatmap!(la, data)

    lagrid[1, 2] = LayoutedColorbar(scene, hmap, width=40)

    on(b2.clicks) do c
        hmap.colormap = rand(setdiff([:viridis, :heat, :rainbow, :blues], [hmap.colormap[]]))
    end
end
