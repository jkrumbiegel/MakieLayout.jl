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
    slidergrid[1, 2] = LayoutedText(scene, text=lift(format, ls1.value),
        alignment=(:left, :center), width=140, padding=(5, 5, 5, 5))
    slidergrid[1, 2] = LayoutedRect(scene, color=:white)

    ls2 = slidergrid[2, 1] = LayoutedSlider(scene, range=LinRange(0.1, 3, 1000), startvalue=1, height=50)
    slidergrid[2, 2] = LayoutedText(scene, text=lift(format, ls2.value),
        alignment=(:left, :center), width=140, padding=(5, 5, 5, 5))
    slidergrid[2, 2] = LayoutedRect(scene, color=:white)

    lines!(la, lift(x -> sin.((0:0.05:10) .* x), ls2.value))
end
