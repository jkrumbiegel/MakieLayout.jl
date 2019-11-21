using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000), camera=campixel!);
    screen = display(scene)

    nrows = 2
    ncols = 2

    maingl = GridLayout(
        nrows, ncols,
        parent = scene,
        alignmode = Outside(30, 30, 30, 30))

    maingl[1, 1] = LayoutedAxis(scene)
    maingl[2, 1] = LayoutedAxis(scene)
    maingl[1, 2] = LayoutedAxis(scene)

    pxarea = Node(IRect2D(BBox(0, 100, 100, 0)))
    subscene = Scene(scene, pxarea)
    maingl[2, 2] = subscene

    scatter!(subscene, rand(1000, 3), markersize=5)

    nothing
end

save("layout.png", scene)

pxarea[] = IRect(755, 87, 531, 506)
