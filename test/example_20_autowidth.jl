using MakieLayout
using Makie


begin
    scene = Scene(camera=campixel!)
    display(scene)

    topgl = GridLayout(parent=scene, alignmode=Outside(30))
    gl = topgl[1, 1] = GridLayout()
    la = gl[1, 1] = LayoutedAxis(scene)
    lc2 = gl[1, 2] = LayoutedColorbar(scene, width=50)

    gl[2, :] = LayoutedSlider(scene, height=40, range=1:1000)
    bgl = gl[3, :] = GridLayout(halign=:left)
    bs = bgl[1, 1:5] = [LayoutedButton(scene, height=40, width=Auto(), label="xx" ^ i) for i in 1:5]
    bgl2 = gl[4, :] = GridLayout()
    b1 = bgl2[1, 1] = LayoutedButton(scene, width = Auto(), label="prev")
    sl1 = bgl2[1, 2] = LayoutedSlider(scene, height=40)
    b2 = bgl2[1, 3] = LayoutedButton(scene, width = Auto(), label="next")

    te = gl[0, :] = LayoutedText(scene, text="Buttons on Buttons", textsize=50)
    nothing
end
