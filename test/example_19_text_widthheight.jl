using Makie
using MakieLayout


begin
    scene = Scene(camera=campixel!)
    screen = display(scene)

    outergrid = GridLayout(scene; alignmode=Outside(30))

    innergrid = outergrid[1, 1] = GridLayout()

    innergrid[1, 1] = LText(scene, text="Hello", textsize=40)
    innergrid[1, 2] = LText(scene, text="Hello", textsize=40, width=80)
    innergrid[1, 3] = LText(scene, text="Hello", textsize=40, width=120)
    innergrid[1, 4] = LText(scene, text="Hello", textsize=40, width=160)
    innergrid[1, 5] = LText(scene, text="Hello", textsize=40, width=180)
    innergrid[1, :] = [LRect(scene) for _ in 1:5]
end
