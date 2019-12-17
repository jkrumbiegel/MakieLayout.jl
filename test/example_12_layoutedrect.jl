using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000), camera=campixel!);
    screen = display(scene)

    nrows = 2
    ncols = 2

    maingl = GridLayout(scene, 1, 1, alignmode=Outside(30))

    gridgl = maingl[1, 1] = GridLayout(
        nrows, ncols)

    r1 = gridgl[1, 1] = LRect(scene, color=:green, strokewidth=10)
    gridgl[1, 2] = LRect(scene, color=:blue)
    gridgl[2, 1] = LRect(scene, color=:red)

    gridgl[2, 2] = LAxis(scene)
    gridgl[2, 2, Top()] = LRect(scene, height=40, strokevisible=false)
    gridgl[2, 2, Left()] = LRect(scene, strokevisible=false)
    gridgl[2, 2, Bottom()] = LRect(scene, strokevisible=false)

    slgl = gridgl[3, :] = GridLayout(1, 1)
    sl = slgl[1, 1] = LSlider(scene, height = 40, range = 0:100)
    but = slgl[1, 2] = LButton(scene, label="Hello")

    sl2 = slgl[2, 1] = LSlider(scene, height = 40, range = 0:100)
    but2 = slgl[2, 2] = LButton(scene, label="Hello Hello")

    on(sl.value) do val
        r1.attributes.strokewidth = val
    end
    nothing
end

# save("layout.png", scene)
