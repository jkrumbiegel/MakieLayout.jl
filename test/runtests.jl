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
    sllength = Node(300.0)
    slheight = 20
    sl = slider!(scene, LinRange(0.2, 5, 301), position=sliderpos,
        sliderlength=sllength, sliderheight=slheight, raw=true,
        textsize = 20, start = 2
        )[end]

    sliderpos2 = Node(Point2(0.0, 0.0))
    sllength2 = Node(300.0)
    slheight2 = 20
    sl2 = slider!(scene, LinRange(0.1, 1, 301), position=sliderpos2,
        sliderlength=sllength2, sliderheight=slheight2, raw=true,
        textsize = 20, start = 1
        )[end]

    xrange = LinRange(0, 2pi, 500)
    lines!(
        la2.scene,
        xrange ./ 2pi .* 100,
        lift((x, y)->sin.(xrange .* x) .* 40 .* y .+ 50, sl.value, sl2.value),
        color=:blue, linewidth=2, show_axis=false)

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
        [Auto(), Aspect(1, 1.0), Auto()],
        [Relative(0.5), Auto()],
        [Fixed(40), Fixed(20)],
        [Fixed(20)],
        Outside(),
        (false, true))

    gl[1, :] = FixedSizeBox(suptitle_bbox, (0.5, 0.0), suptitle_pos)

    gl_slider = GridLayout(
        [], 3, 1,
        [Auto(), Auto(), Auto()],
        [Relative(1)],
        [Fixed(15)],
        [],
        Inside(),
        (false, false))

    gl_slider[1, 1] = AxisLayout(BBox(75, 0, 0, 75), la2)

    gl_slider[2, 1] = FixedHeightBox(slheight, 0.5, (ibbox, obbox)->begin ibbox, obbox
        sllength[] = width(ibbox) - 30
        sliderpos[] = Point2(left(ibbox), bottom(ibbox))
    end)
    gl_slider[3, 1] = FixedHeightBox(slheight2, 0.5, (ibbox, obbox)->begin ibbox, obbox
        sllength2[] = width(ibbox) - 30
        sliderpos2[] = Point2(left(ibbox), bottom(ibbox))
    end)

    gl[2, 2] = gl_slider

    gl_sub = GridLayout(
        [], 2, 1,
        [Auto(), Auto()],
        [Relative(1)],
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


begin
    scene = Scene(resolution = (1000, 1000), font="SF Hello");
    screen = display(scene)
    campixel!(scene);

    gl = GridLayout(
        scene, 3, 3,
        [Auto(), Auto(), Auto()],
        [Auto(), Auto(), Auto()],
        [Fixed(0), Fixed(0)],
        [Fixed(0), Fixed(0)],
        Outside(30, 30, 30, 30),
        (false, false)
    )

    las = []
    for i in 1:3, j in 1:3
        # la =
        # al = AxisLayout(gl, la.protrusions, la.bboxnode)
        la = gl[i, j] = LayoutedAxis(scene)
        scatter!(la.scene, rand(100, 2) .* 90 .+ 5, color=RGBf0(rand(3)...), raw=true, markersize=5)
        push!(las, la)
    end
end


begin
    begin
        for i in 1:9
            las[i].ylabelvisible[] = false
            las[i].xlabelvisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].yticklabelsvisible[] = false
            las[i].xticklabelsvisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].titlevisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].ylabelvisible[] = true
            las[i].xlabelvisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].yticklabelsvisible[] = true
            las[i].xticklabelsvisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].titlevisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].title[] = "Big\nTitle"
            las[i].ylabel[] = "Big\ny label"
            las[i].xlabel[] = "Big\nx label"
            sleep(0.05)
        end

        for i in 1:9
            las[i].title[] = "Title"
            las[i].ylabel[] = "y label"
            las[i].xlabel[] = "x label"
            sleep(0.05)
        end
    end
    begin
        for i in 1:9
            las[i].ylabelsize[] = 30
            las[i].xlabelsize[] = 30
            las[i].yticklabelsize[] = 30
            las[i].xticklabelsize[] = 30
            sleep(0.05)
        end

        for i in 1:9
            las[i].ylabelsize[] = 20
            las[i].xlabelsize[] = 20
            las[i].yticklabelsize[] = 20
            las[i].xticklabelsize[] = 20
            sleep(0.05)
        end
    end
end
