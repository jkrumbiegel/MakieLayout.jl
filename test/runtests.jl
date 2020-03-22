using MakieLayout
using AbstractPlotting
using Test

include("debugrect.jl")

# have BBoxes show as such because the default is very verbose
Base.show(io::IO, bb::BBox) = print(io, "BBox(l: $(left(bb)), r: $(right(bb)), b: $(bottom(bb)), t: $(top(bb)))")


@testset "GridLayout Zero Outside AlignMode" begin
    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Outside(0))
    dr = layout[1, 1] = DebugRect()

    @test dr.layoutobservables.computedbbox[] == bbox

    dr.topprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(0, 1000, 0, 900)
    dr.bottomprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(0, 1000, 100, 900)
    dr.leftprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(100, 1000, 100, 900)
    dr.rightprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(100, 900, 100, 900)

    dr2 = layout[1, 2] = DebugRect()
    @test layout.nrows == 1 && layout.ncols == 2
    colgap!(layout, 1, Fixed(0))

    @test dr.layoutobservables.computedbbox[].widths == dr2.layoutobservables.computedbbox[].widths == Float32[400.0, 800.0]
end

@testset "GridLayout Outside AlignMode" begin
    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Outside(100, 200, 50, 150))
    dr = layout[1, 1] = DebugRect()

    @test dr.layoutobservables.computedbbox[] == BBox(100, 800, 50, 850)

    dr.topprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(100, 800, 50, 750)
    dr.bottomprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(100, 800, 150, 750)
    dr.leftprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(200, 800, 150, 750)
    dr.rightprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(200, 700, 150, 750)
end

@testset "GridLayout Inside AlignMode" begin
    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Inside())
    dr = layout[1, 1] = DebugRect()

    @test dr.layoutobservables.computedbbox[] == BBox(0, 1000, 0, 1000)

    dr.topprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(0, 1000, 0, 1000)
    dr.bottomprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(0, 1000, 0, 1000)
    dr.leftprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(0, 1000, 0, 1000)
    dr.rightprot = 100
    @test dr.layoutobservables.computedbbox[] == BBox(0, 1000, 0, 1000)
end

@testset "GridLayout Mixed AlignMode" begin
    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Mixed(left = 0, top = 100))
    dr = layout[1, 1] = DebugRect()

    @test MakieLayout.protrusion(layout, Left()) == 0
    @test MakieLayout.protrusion(layout, Right()) == 0
    @test MakieLayout.protrusion(layout, Bottom()) == 0
    @test MakieLayout.protrusion(layout, Top()) == 0

    @test dr.layoutobservables.computedbbox[] == BBox(0, 1000, 0, 900)

    dr.topprot = 100
    @test MakieLayout.protrusion(layout, Top()) == 0
    @test dr.layoutobservables.computedbbox[] == BBox(0, 1000, 0, 800)

    dr.bottomprot = 100
    @test MakieLayout.protrusion(layout, Bottom()) == 100
    @test dr.layoutobservables.computedbbox[] == BBox(0, 1000, 0, 800)

    dr.leftprot = 100
    @test MakieLayout.protrusion(layout, Left()) == 0
    @test dr.layoutobservables.computedbbox[] == BBox(100, 1000, 0, 800)

    dr.rightprot = 100
    @test MakieLayout.protrusion(layout, Right()) == 100
    @test dr.layoutobservables.computedbbox[] == BBox(100, 1000, 0, 800)
end

@testset "Layoutables constructors" begin
    scene, layout = layoutscene()
    ax = layout[1, 1] = LAxis(scene)
    cb = layout[1, 2] = LColorbar(scene)
    gl2 = layout[2, :] = GridLayout()
    bu = gl2[1, 1] = LButton(scene)
    sl = gl2[1, 2] = LSlider(scene)

    scat = scatter!(ax, rand(10))
    le = gl2[1, 3] = LLegend(scene, [scat], ["scatter"])

    to = gl2[1, 4] = LToggle(scene)
    te = layout[0, :] = LText(scene, "A super title")
end
