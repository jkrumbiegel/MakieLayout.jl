using Makie
using MakieLayout
using Printf

begin
    scene = Scene(camera=campixel!)
    screen = display(scene)

    outergrid = GridLayout(scene; alignmode=Outside(30))

    innergrid = outergrid[1, 1] = GridLayout()

    la = innergrid[1, 1] = LayoutedAxis(scene)

    slidergrid = innergrid[2, 1] = GridLayout()

    ls1 = slidergrid[1, 1] = LayoutedSlider(scene, range=50:0.01:100, height=50)
    slidergrid[1, 2] = LayoutedText(scene, text=lift(x->@sprintf("%.2f", x), ls1.value),
        alignment=(:right, :center), width=140, padding=(5, 5, 5, 5))
    slidergrid[1, 2] = LayoutedRect(scene, color=:white, strokewidth=1f0)

    ls2 = slidergrid[2, 1] = LayoutedSlider(scene, range=LinRange(0.1, 3, 1000), startvalue=1, height=50)
    slidergrid[2, 2] = LayoutedText(scene, text=lift(x->@sprintf("%.2f", x), ls2.value),
        alignment=(:right, :center), width=140, padding=(5, 5, 5, 5))
    slidergrid[2, 2] = LayoutedRect(scene, color=:white, strokewidth=1f0)

    ls3 = innergrid[1, end+1] = LayoutedSlider(scene, range=0:0.01:1, width=50, horizontal=false)

    lines!(la, lift((x, y)-> sin.((0:0.05:10) .* x) .* y, ls2.value, ls3.value))

end
