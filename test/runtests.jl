using MakieLayout
using AbstractPlotting
using Test

include("debugrect.jl")


@testset "GridLayout 1" begin
    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Outside(0))
    dr = layout[1, 1] = DebugRect()

    @test dr.layoutnodes.computedbbox[] == bbox

    dr.topprot = 100
    @test dr.layoutnodes.computedbbox[] == BBox(0, 1000, 0, 900)
    dr.bottomprot = 100
    @test dr.layoutnodes.computedbbox[] == BBox(0, 1000, 100, 900)
    dr.leftprot = 100
    @test dr.layoutnodes.computedbbox[] == BBox(100, 1000, 100, 900)
    dr.rightprot = 100
    @test dr.layoutnodes.computedbbox[] == BBox(100, 900, 100, 900)

    dr2 = layout[1, 2] = DebugRect()
    @test layout.nrows == 1 && layout.ncols == 2
    colgap!(layout, 1, Fixed(0))

    @test dr.layoutnodes.computedbbox[].widths == dr2.layoutnodes.computedbbox[].widths
end
