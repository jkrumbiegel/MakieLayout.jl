using MakieLayout
using Makie
using KernelDensity

function kdepoly!(scene, vec, scalevalue, reverse=false; kwargs...)
    kderesult = kde(vec; npoints=32)

    x = kderesult.x
    y = kderesult.density
    y = y .* (1 / maximum(y)) .* scalevalue

    if reverse
        poly!(scene, Point2.(y, x); kwargs...)[end]
    else
        poly!(scene, Point2.(x, y); kwargs...)[end]
    end
end

begin
    scene = Scene(resolution = (1000, 1000));
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

    sliderpos = Node(Point2(0.0, 0.0))
    sllength = 300
    slheight = 20
    sl = slider!(scene, LinRange(0.2, 5, 301), position=sliderpos,
        sliderlength=sllength, sliderheight=slheight, raw=true,
        textsize = 20, start = 2
        )[end]

    xrange = LinRange(0, 2pi, 500)
    lines!(la2.scene, xrange ./ 2pi .* 100, lift(x->sin.(xrange .* x) .* 40 .+ 50, sl.value), color=:blue, show_axis=false)

    linkeddata = randn(200, 2) .* 15 .+ 50
    green = RGBAf0(0.05, 0.8, 0.3, 0.6)
    scatter!(la3.scene, linkeddata, markersize=3, color=green, show_axis=false)

    kdepoly!(la4.scene, linkeddata[:, 1], 90, false, color=green, linewidth=2, show_axis=false)
    kdepoly!(la5.scene, linkeddata[:, 2], 90, true, color=green, linewidth=2, show_axis=false)
    update!(scene)

    suptitle_pos = Node(Point2(0.0, 0.0))
    suptitle = text!(scene, "Centered Super Title", position=suptitle_pos, textsize=50)[end]
    suptitle_bbox = BBox(boundingbox(suptitle))

    midtitle_pos = Node(Point2(0.0, 0.0))
    midtitle = text!(scene, "Left aligned subtitle", position=midtitle_pos, textsize=40)[end]
    midtitle_bbox = BBox(boundingbox(midtitle))

    gl = GridLayout(
        [], 3, 2,
        [Auto(), Aspect(1, 1.0), Ratio(2)],
        [Relative(0.5), Auto()],
        [Fixed(40), Fixed(20)],
        [Fixed(20)],
        Outside(),
        (false, true))

    gl[1, :] = FixedSizeBox(suptitle_bbox, (0.5, 0.0), suptitle_pos)

    gl_slider = GridLayout(
        [], 2, 1,
        [Auto(), Auto()],
        [Relative(1)],
        [Fixed(15)],
        [],
        Inside(),
        (false, false))

    gl_slider[1, 1] = AxisLayout(BBox(75, 0, 0, 75), la2)

    gl_slider[2, 1] = FixedSizeBox(BBox(0, sllength, slheight, 0), (0.0, 0.0), sliderpos)

    gl[2, 2] = gl_slider

    gl_sub = GridLayout(
        [], 2, 1,
        [Auto(), Auto()],
        [Ratio(1)],
        [Fixed(15)],
        [],
        Inside(),
        (true, true))

    gl_sub[1, 1] = FixedSizeBox(midtitle_bbox, (0.0, 0.0), midtitle_pos)
    gl_sub[2, 1] = AxisLayout(BBox(75, 0, 0, 75), la1)

    gl[3, :] = gl_sub

    gl2 = GridLayout(
        [], 2, 2,
        [Auto(), Relative(0.7)],
        [Aspect(2, 1.0), Auto()],
        [Relative(0)],
        [Relative(0)],
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
