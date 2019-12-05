using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000), camera=campixel!);
    screen = display(scene)

    nrows = 2
    ncols = 2

    maingl = GridLayout(1, 1, parent=scene, alignmode=Outside(30))

    gridgl = maingl[1, 1] = GridLayout(
        nrows, ncols)

    r1 = gridgl[1, 1] = LayoutedRect(scene, color=:green, strokewidth=10)
    gridgl[1, 2] = LayoutedRect(scene, color=:blue)
    gridgl[2, 1] = LayoutedRect(scene, color=:red)

    gridgl[2, 2] = LayoutedAxis(scene)
    gridgl[2, 2, Top()] = LayoutedRect(scene, height=40, strokevisible=false)
    gridgl[2, 2, Left()] = LayoutedRect(scene, strokevisible=false)
    gridgl[2, 2, Bottom()] = LayoutedRect(scene, strokevisible=false)

    slgl = gridgl[3, :] = GridLayout(1, 1)
    sl = slgl[1, 1] = LayoutedSlider(scene, height = 40, range = 0:100)
    but = slgl[1, 2] = LayoutedButton(scene, label="Hello")

    sl2 = slgl[2, 1] = LayoutedSlider(scene, height = 40, range = 0:100)
    but2 = slgl[2, 2] = LayoutedButton(scene, label="Hello Hello")

    on(sl.value) do val
        r1.attributes.strokewidth = val
    end
    nothing
end

# save("layout.png", scene)
