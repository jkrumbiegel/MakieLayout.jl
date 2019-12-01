using Makie
using MakieLayout


begin
    scene = Scene(camera=campixel!)
    screen = display(scene)

    outergrid = GridLayout(scene; alignmode=Outside(30))

    innergrid = outergrid[1, 1] = GridLayout(2, 2)

    innergrid[1, :] = LayoutedAxis(scene)
    ls1 = innergrid[2, :] = LayoutedSlider(scene, range=50:0.01:100, height=50)
    innergrid[3, :] = LayoutedSlider(scene, height=50)

    innergrid[0, :] = LayoutedText(scene, textsize=ls1.value)
end
