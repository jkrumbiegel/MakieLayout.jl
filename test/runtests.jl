using MakieLayout
using Makie

begin
    scene = Scene(resolution = (600, 600));
    screen = display(scene)
    campixel!(scene);

    la1 = LayoutedAxis(scene)
    la2 = LayoutedAxis(scene)
    la3 = LayoutedAxis(scene)
    la4 = LayoutedAxis(scene)
    la5 = LayoutedAxis(scene)

    linkxaxes!(la3, la4)
    linkyaxes!(la3, la5)

    # lines!(la1.scene, rand(200, 2) .* 100, color=:black, show_axis=false)
    img = rand(100, 100)
    image!(la1.scene, img, show_axis=false)
    lines!(la2.scene, rand(200, 2) .* 100, color=:blue, show_axis=false)

    linkeddata = rand(200, 2) .* 100
    scatter!(la3.scene, linkeddata, markersize=3, color=:red, show_axis=false)
    scatter!(la4.scene, linkeddata, markersize=3, color=:orange, show_axis=false)
    scatter!(la5.scene, linkeddata, markersize=3, color=:pink, show_axis=false)
    update!(scene)

    gl = GridLayout([], 2, 2, [1, 1], [1, 1], 0.01, 0.01, Outside())

    gl[2, 1:2] = AxisLayout(BBox(75, 0, 0, 75), la1)
    gl[1, 2] = AxisLayout(BBox(75, 0, 0, 75), la2)

    gl2 = GridLayout([], 2, 2, [0.2, 0.8], [0.8, 0.2], 0.01, 0.01, Inside())
    gl2[2, 1] = AxisLayout(BBox(75, 0, 0, 75), la3)
    gl2[1, 1] = AxisLayout(BBox(75, 0, 0, 75), la4)
    gl2[2, 2] = AxisLayout(BBox(75, 0, 0, 75), la5)

    gl[1, 1] = gl2

    sg = solve(gl, BBox(shrinkbymargin(pixelarea(scene)[], 30)))
    applylayout(sg)
    # when the scene is resized, apply the outersolve'd outermost grid layout
    # this recursively updates all layout objects that are contained in the grid
    on(scene.events.window_area) do area
    sg = solve(gl, BBox(shrinkbymargin(pixelarea(scene)[], 30)))
        applylayout(sg)
    end
end
