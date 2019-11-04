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

    suptitle_pos = Node(Point2(0.0, 0.0))
    suptitle = text!(scene, "Centered Super Title", position=suptitle_pos, textsize=50)[end]
    suptitle_bbox = BBox(boundingbox(suptitle))

    midtitle_pos = Node(Point2(0.0, 0.0))
    midtitle = text!(scene, "Left aligned subtitle", position=midtitle_pos, textsize=40)[end]
    midtitle_bbox = BBox(boundingbox(midtitle))

    gl = GridLayout(
        [], 3, 2,
        [Auto(), Ratio(3), Ratio(2)],
        [Relative(0.6), Auto()],
        [Fixed(40), Fixed(20)],
        [Fixed(20)],
        Outside(),
        (false, true))

    gl[1, :] = FixedSizeBox(suptitle_bbox, (0.5, 0.0), suptitle_pos)
    gl[2, 2] = AxisLayout(BBox(75, 0, 0, 75), la2)

    gl_sub = GridLayout(
        [], 2, 1,
        [Auto(), Auto()],
        [Ratio(1)],
        [Relative(0.03)],
        [],
        Inside(),
        (true, true))

    gl_sub[1, 1] = FixedSizeBox(midtitle_bbox, (0.0, 0.0), midtitle_pos)
    gl_sub[2, 1] = AxisLayout(BBox(75, 0, 0, 75), la1)

    gl[3, :] = gl_sub

    gl2 = GridLayout(
        [], 2, 2,
        [Fixed(150), Auto()],
        Relative.([0.8, 0.2]),
        [Relative(0.03)],
        [Relative(0.03)],
        Inside(),
        (true, true))

    gl2[2, 1] = AxisLayout(BBox(75, 0, 0, 75), la3)
    gl2[1, 1] = AxisLayout(BBox(75, 0, 0, 75), la4)
    gl2[2, 2] = AxisLayout(BBox(75, 0, 0, 75), la5)

    gl[2, 1] = gl2

    padding = 30
    sg = solve(gl, BBox(shrinkbymargin(pixelarea(scene)[], padding)))
    applylayout(sg)
    # when the scene is resized, apply the outersolve'd outermost grid layout
    # this recursively updates all layout objects that are contained in the grid
    on(scene.events.window_area) do area
    sg = solve(gl, BBox(shrinkbymargin(pixelarea(scene)[], padding)))
        applylayout(sg)
    end
end
