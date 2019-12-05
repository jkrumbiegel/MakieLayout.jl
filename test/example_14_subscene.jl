using MakieLayout
using Makie

function stupid_subscenes(
        parent::Scene, px_area;
        events = scene.events,
        theme = copy(theme(scene)),
        current_screens = scene.current_screens,
        clear = true,
        scene_attributes...
    )
    child = Scene(
        events,
        px_area,
        Camera(px_area),
        Base.RefValue{Any}(EmptyCamera()),
        nothing,
        Transformation(),
        AbstractPlot[],
        merge(AbstractPlotting.current_default_theme(), theme),
        merge!(Attributes(clear = clear; scene_attributes...), scene.attributes),
        Scene[],
        current_screens
    )
    # Set the transformation parent
    child.transformation.parent[] = child
    push!(scene.children, child)
    child
end

MakieLayout.defaultlayout(s::Scene) = ProtrusionLayout(s)
MakieLayout.protrusionnode(s::Scene) = Node(MakieLayout.RectSides(0f0, 0f0, 0f0, 0f0))
MakieLayout.computedsizenode(s::Scene) = Node{NTuple{2, MakieLayout.Optional{Float32}}}((nothing, nothing))

function MakieLayout.align_to_bbox!(s::Scene, bbox)
    pixelarea(s)[] = IRect2D(bbox)
end

begin
    scene = Scene(resolution = (1000, 1000));
    screen = display(scene)
    campixel!(scene);

    nrows = 2
    ncols = 2

    maingl = GridLayout(1, 1, parent=scene, alignmode=Outside(30))

    gridgl = maingl[1, 1] = GridLayout(
        nrows, ncols)

    la1 = gridgl[1, :] = LayoutedAxis(scene)
    la2 = gridgl[2, 1] = LayoutedAxis(scene)

    # linkxaxes!(la1, la2)
    # linkyaxes!(la1, la2)

    scatter!(la1, rand(10_000, 2), markersize=10)

    subscene = stupid_subscenes(scene, Node(IRect2D(BBox(0, 100, 100, 0))))
    subscene.backgroundcolor = RGBf0(0.96, 0.96, 0.96)
    subscene.clear = true
    gridgl[2, 2] = subscene

    scatter!(subscene, rand(100, 3), markersize=10, show_axis=true)

    # display(scene)

    slidergl = gridgl[3, :] = GridLayout(1, 1)
    slidergl[1, 1] = LayoutedText(scene, text="Turbulence", halign=:left)
    slidergl[1, 2] = LayoutedSlider(scene, height = 30, range = 0.0:0.1:100.0, buttonsize=20, textsize=20)
    slidergl[1, 3] = LayoutedButton(scene, label="Press this")
    slidergl.colsizes[3] = Fixed(200)
    slidergl[2, 1] = LayoutedText(scene, text="Gamma Factor", halign=:left)
    slidergl[2, 2] = LayoutedSlider(scene, height = 30, range = 0.0:0.1:100.0, buttonsize=20, textsize=20)
    slidergl[2, 3] = LayoutedButton(scene, label="Press that")
    slidergl[3, 1] = LayoutedText(scene, text="Precision", halign=:left)
    slidergl[3, 2] = LayoutedSlider(scene, height = 30, range = 0.0:0.1:100.0, buttonsize=20, textsize=20)
    slidergl[3, 3] = LayoutedButton(scene, label="And this too")


    nothing
end

tight_ticklabel_spacing!(gridgl[1, 1:2].content)

gridgl[1:2, 1].content.xticklabelrotation = pi/8
gridgl[1:2, 1].content.xticklabelalign = (:top, :center)
