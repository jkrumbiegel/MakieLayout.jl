using Random
using Animations
using PlotUtils
using Makie
import Showoff

struct BBox
    left::Float64
    right::Float64
    top::Float64
    bottom::Float64
end

mutable struct LayoutedAxis
    parent::Scene
    scene::Scene
    xlabel::Node{String}
    ylabel::Node{String}
    limits::Node{FRect2D}
end

width(b::BBox) = b.right - b.left
height(b::BBox) = b.top - b.bottom

abstract type Alignable end

struct Span
    rows::UnitRange{Int64}
    cols::UnitRange{Int64}
end

struct SpannedAlignable{T<:Alignable}
    al::T
    sp::Span
end

isleftmostin(sp::SpannedAlignable, grid) = sp.sp.cols.start == 1
isrightmostin(sp::SpannedAlignable, grid) = sp.sp.cols.stop == grid.ncols
isbottommostin(sp::SpannedAlignable, grid) = sp.sp.rows.stop == grid.nrows
istopmostin(sp::SpannedAlignable, grid) = sp.sp.cols.start == 1

struct SolvedAxisLayout <: Alignable
    inner::BBox
    outer::BBox
    axis::LayoutedAxis
end

struct AxisLayout <: Alignable
    decorations::BBox
    axis::LayoutedAxis
end

struct SolvedGridLayout <: Alignable
    bbox::BBox
    content::Vector{SpannedAlignable}
    nrows::Int
    ncols::Int
    xleftcols::Vector{Float64}
    xrightcols::Vector{Float64}
    ytoprows::Vector{Float64}
    ybottomrows::Vector{Float64}
end

struct GridLayout <: Alignable
    content::Vector{SpannedAlignable}
    nrows::Int
    ncols::Int
    colratios::Vector{Float64}
    rowratios::Vector{Float64}
    colgapfraction::Float64
    rowgapfraction::Float64
end

leftprotrusion(u::AxisLayout) = u.decorations.left
leftprotrusion(s::SolvedAxisLayout) = s.inner.left - s.outer.left
leftprotrusion(sp::SpannedAlignable) = leftprotrusion(sp.al)

function leftprotrusion(gl::GridLayout)
    leftmosts = filter(x -> isleftmostin(x, gl), gl.content)
    if isempty(leftmosts)
        0.0
    else
        maximum(leftprotrusion.(leftmosts))
    end
end

rightprotrusion(u::AxisLayout) = u.decorations.right
rightprotrusion(s::SolvedAxisLayout) = s.outer.right - s.inner.right
rightprotrusion(sp::SpannedAlignable) = rightprotrusion(sp.al)

function rightprotrusion(gl::GridLayout)
    rightmosts = filter(x -> isrightmostin(x, gl), gl.content)
    if isempty(rightmosts)
        0.0
    else
        maximum(rightprotrusion.(rightmosts))
    end
end

topprotrusion(u::AxisLayout) = u.decorations.top
topprotrusion(s::SolvedAxisLayout) = s.outer.top - s.inner.top
topprotrusion(sp::SpannedAlignable) = topprotrusion(sp.al)

function topprotrusion(gl::GridLayout)
    topmosts = filter(x -> istopmostin(x, gl), gl.content)
    if isempty(topmosts)
        0.0
    else
        maximum(topprotrusion.(topmosts))
    end
end

bottomprotrusion(u::AxisLayout) = u.decorations.bottom
bottomprotrusion(s::SolvedAxisLayout) = s.outer.bottom - s.inner.bottom
bottomprotrusion(sp::SpannedAlignable) = bottomprotrusion(sp.al)

function bottomprotrusion(gl::GridLayout)
    bottommosts = filter(x -> isbottommostin(x, gl), gl.content)
    if isempty(bottommosts)
        0.0
    else
        maximum(bottomprotrusion.(bottommosts))
    end
end

function solve(gl::GridLayout, bbox::BBox) # when the grid is inside some other grid
    maxcollefts = zeros(gl.ncols)
    maxcolrights = zeros(gl.ncols)
    maxrowtops = zeros(gl.nrows)
    maxrowbottoms = zeros(gl.nrows)

    for c in gl.content
        ileft = c.sp.cols.start
        iright = c.sp.cols.stop
        itop = c.sp.rows.start
        ibottom = c.sp.rows.stop

        maxcollefts[ileft] = max(maxcollefts[ileft], leftprotrusion(c.al))
        maxcolrights[iright] = max(maxcolrights[iright], rightprotrusion(c.al))
        maxrowtops[itop] = max(maxrowtops[itop], topprotrusion(c.al))
        maxrowbottoms[ibottom] = max(maxrowbottoms[ibottom], bottomprotrusion(c.al))
    end

    colgaps = maxcollefts[2:end] .+ maxcolrights[1:end-1]
    rowgaps = maxrowtops[2:end] .+ maxrowbottoms[1:end-1]

    maxcolgap = maximum(colgaps)
    maxrowgap = maximum(rowgaps)

    sumcolgaps = maxcolgap * (gl.ncols - 1)
    sumrowgaps = maxrowgap * (gl.nrows - 1)

    # removed prots
    remaininghorizontalspace = width(bbox) - sumcolgaps
    remainingverticalspace = height(bbox) - sumrowgaps

    addedcolgap = gl.colgapfraction * remaininghorizontalspace
    addedrowgap = gl.rowgapfraction * remainingverticalspace

    spaceforcolumns = remaininghorizontalspace - addedcolgap * (gl.ncols - 1)
    spaceforrows = remainingverticalspace - addedrowgap * (gl.nrows - 1)

    colwidths = gl.colratios ./ sum(gl.colratios) .* spaceforcolumns
    rowheights = gl.rowratios ./ sum(gl.rowratios) .* spaceforrows

    colgap = maxcolgap + addedcolgap
    rowgap = maxrowgap + addedrowgap

    # removed leftprot
    xleftcols = [bbox.left + sum(colwidths[1:i-1]) + (i - 1) * colgap for i in 1:gl.ncols]
    xrightcols = xleftcols .+ colwidths

    # removed topprot
    ytoprows = [bbox.top - sum(rowheights[1:i-1]) - (i - 1) * rowgap for i in 1:gl.nrows]
    ybottomrows = ytoprows .- rowheights

    solvedcontent = SpannedAlignable[]
    for c in gl.content
        ileft = c.sp.cols.start
        iright = c.sp.cols.stop
        itop = c.sp.rows.start
        ibottom = c.sp.rows.stop

        bbox_cell = Main.BBox(
            xleftcols[ileft], xrightcols[iright], ytoprows[itop], ybottomrows[ibottom])

        solved = solve(c.al, bbox_cell)
        push!(solvedcontent, SpannedAlignable(solved, c.sp))
    end

    # solvedcontent = solve.(gl.content)
    SolvedGridLayout(bbox, solvedcontent, gl.nrows, gl.ncols, xleftcols,
        xrightcols, ytoprows, ybottomrows)
end

function outersolve(gl::GridLayout, bbox::BBox)
    maxcollefts = zeros(gl.ncols)
    maxcolrights = zeros(gl.ncols)
    maxrowtops = zeros(gl.nrows)
    maxrowbottoms = zeros(gl.nrows)

    for c in gl.content
        ileft = c.sp.cols.start
        iright = c.sp.cols.stop
        itop = c.sp.rows.start
        ibottom = c.sp.rows.stop

        maxcollefts[ileft] = max(maxcollefts[ileft], leftprotrusion(c.al))
        maxcolrights[iright] = max(maxcolrights[iright], rightprotrusion(c.al))
        maxrowtops[itop] = max(maxrowtops[itop], topprotrusion(c.al))
        maxrowbottoms[ibottom] = max(maxrowbottoms[ibottom], bottomprotrusion(c.al))
    end

    topprot = maxrowtops[1]
    bottomprot = maxrowbottoms[end]
    leftprot = maxcollefts[1]
    rightprot = maxcolrights[end]

    colgaps = maxcollefts[2:end] .+ maxcolrights[1:end-1]
    rowgaps = maxrowtops[2:end] .+ maxrowbottoms[1:end-1]

    maxcolgap = gl.ncols <= 1 ? 0 : maximum(colgaps)
    maxrowgap = gl.nrows <= 1 ? 0 : maximum(rowgaps)

    sumcolgaps = maxcolgap * (gl.ncols - 1)
    sumrowgaps = maxrowgap * (gl.nrows - 1)

    remaininghorizontalspace = width(bbox) - sumcolgaps - leftprot - rightprot
    remainingverticalspace = height(bbox) - sumrowgaps - topprot - bottomprot

    addedcolgap = gl.colgapfraction * remaininghorizontalspace
    addedrowgap = gl.rowgapfraction * remainingverticalspace

    spaceforcolumns = remaininghorizontalspace - addedcolgap * (gl.ncols - 1)
    spaceforrows = remainingverticalspace - addedrowgap * (gl.nrows - 1)

    colwidths = gl.colratios ./ sum(gl.colratios) .* spaceforcolumns
    rowheights = gl.rowratios ./ sum(gl.rowratios) .* spaceforrows

    colgap = maxcolgap + addedcolgap
    rowgap = maxrowgap + addedrowgap

    xleftcols = [bbox.left + leftprot + sum(colwidths[1:i-1]) + (i - 1) * colgap for i in 1:gl.ncols]
    xrightcols = xleftcols .+ colwidths

    ytoprows = [bbox.top - topprot - sum(rowheights[1:i-1]) - (i - 1) * rowgap for i in 1:gl.nrows]
    ybottomrows = ytoprows .- rowheights

    solvedcontent = SpannedAlignable[]
    for c in gl.content
        ileft = c.sp.cols.start
        iright = c.sp.cols.stop
        itop = c.sp.rows.start
        ibottom = c.sp.rows.stop

        bbox_cell = Main.BBox(
            xleftcols[ileft], xrightcols[iright], ytoprows[itop], ybottomrows[ibottom])

        solved = solve(c.al, bbox_cell)
        push!(solvedcontent, SpannedAlignable(solved, c.sp))
    end

    # solvedcontent = solve.(gl.content)
    SolvedGridLayout(bbox, solvedcontent, gl.nrows, gl.ncols, xleftcols,
        xrightcols, ytoprows, ybottomrows)
end

function solve(ua::AxisLayout, innerbbox)
    ol = innerbbox.left - ua.decorations.left
    or = innerbbox.right + ua.decorations.right
    ot = innerbbox.top - ua.decorations.top
    ob = innerbbox.bottom + ua.decorations.bottom
    SolvedAxisLayout(innerbbox, Main.BBox(ol, or, ot, ob), ua.axis)
end

Base.setindex!(g, a::Alignable, rows::S, cols::T) where {T<:Union{UnitRange,Int,Colon}, S<:Union{UnitRange,Int,Colon}} = begin

    if typeof(rows) <: Int
        rows = rows:rows
    elseif typeof(rows) <: Colon
        rows = 1:g.nrows
    end
    if typeof(cols) <: Int
        cols = cols:cols
    elseif typeof(cols) <: Colon
        cols = 1:g.ncols
    end

    if !((1 <= rows.start <= g.nrows) || (1 <= rows.stop <= g.nrows))
        error("invalid row span $rows for grid with $(g.nrows) rows")
    end
    if !((1 <= cols.start <= g.ncols) || (1 <= cols.stop <= g.ncols))
        error("invalid col span $cols for grid with $(g.ncols) columns")
    end
    push!(g.content, SpannedAlignable(a, Span(rows, cols)))
end

function axislines!(scene, rect)
    points = lift(rect) do r
        p1 = Point2(r.origin[1], r.origin[2] + r.widths[2])
        p2 = Point2(r.origin[1], r.origin[2])
        p3 = Point2(r.origin[1] + r.widths[1], r.origin[2])
        [p1, p2, p3]
    end
    lines!(scene, points, linewidth=2, show_axis=false)
end

function locateticks(xmin, xmax)
    d = xmax - xmin
    ex = log10(d)
    exrounded = round(ex)
    factor = 1 / 10 ^ (exrounded - 1)

    xminf = ceil(xmin * factor)
    xmaxf = floor(xmax * factor)

    df = xmaxf - xminf

    steps = [5, 4, 2, 1]

    for s in steps
        n, remainder = divrem(df, s)
        if n >= 2
            rang = 1:n
            ticks = [xminf; [xminf + x * s for x in rang]] ./ factor
            return ticks
        end
    end
end

function LayoutedAxis(parent::Scene)
    scene = Scene(parent, Node(IRect(0, 0, 100, 100)))
    limits = Node(FRect(0, 0, 100, 100))
    xlabel = Node("x label")
    ylabel = Node("y label")

    cam = cam2d!(scene)

    ticksnode = Node(Point2f0[])
    ticks = linesegments!(parent, ticksnode, linewidth=2)[end]

    nmaxticks = 7

    xticklabelnodes = [Node("0") for i in 1:nmaxticks]
    xticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    xticklabels = [text!(parent,
        xticklabelnodes[i],
        position = xticklabelposnodes[i],
        align = (:center, :top),
        textsize=20)[end]
            for i in 1:nmaxticks]

    on(cam.area) do a
        # @show a = scene.limits[]
        xrange = (a.origin[1], a.origin[1] + a.widths[1])
        width = xrange[2] - xrange[1]

        if width == 0 || !isfinite(xrange[1]) || !isfinite(xrange[2])
            return
        end

        xtickvals = locateticks(xrange...)
        # xtickvals, vminbest, vmaxbest = optimize_ticks(xrange...)
        xfractions = (xtickvals .- xrange[1]) ./ width
        pxa = scene.px_area[]
        xrange_scene = (pxa.origin[1], pxa.origin[1] + pxa.widths[1])
        width_scene = xrange_scene[2] - xrange_scene[1]
        xticks_scene = xrange_scene[1] .+ width_scene .* xfractions
        ticksize = 10 # px
        y = pxa.origin[2]
        xtickstarts = [Point(x, y) for x in xticks_scene]
        xtickends = [t + Point(0.0, -ticksize) for t in xtickstarts]

        yrange = (a.origin[2], a.origin[2] + a.widths[2])
        height = yrange[2] - yrange[1]
        ytickvals = locateticks(yrange...)
        # ytickvals, vminbest, vmaxbest = optimize_ticks(yrange...)
        yfractions = (ytickvals .- yrange[1]) ./ height
        pxa = scene.px_area[]
        yrange_scene = (pxa.origin[2], pxa.origin[2] + pxa.widths[2])
        height_scene = yrange_scene[2] - yrange_scene[1]
        yticks_scene = yrange_scene[1] .+ height_scene .* yfractions
        ticksize = 10 # px
        x = pxa.origin[1]
        ytickstarts = [Point(x, y) for y in yticks_scene]
        ytickends = [t + Point(-ticksize, 0.0) for t in ytickstarts]

        xtickstrings = Showoff.showoff(xtickvals, :plain)
        nxticks = length(xtickvals)
        for i in 1:nmaxticks
            if i <= nxticks
                xticklabelnodes[i][] = xtickstrings[i]
                xticklabelposnodes[i][] = xtickends[i] + Point(0.0, -10.0)
                xticklabels[i].visible = true
            else
                xticklabels[i].visible = false
            end
        end


        ticksnode[] = collect(Iterators.flatten(zip(
           [xtickstarts; ytickstarts],
           [xtickends; ytickends])))
    end

    labelgap = 40

    xlabelpos = lift(scene.px_area) do a
        Point2(a.origin[1] + a.widths[1] / 2, a.origin[2] - labelgap)
    end

    ylabelpos = lift(scene.px_area) do a
        Point2(a.origin[1] - labelgap, a.origin[2] + a.widths[2] / 2)
    end

    tx = text!(parent, xlabel, textsize=20, position=xlabelpos, show_axis=false)[end]
    tx.align = [0.5, 1]
    ty = text!(parent, ylabel, textsize=20, position=ylabelpos, rotation=pi/2, show_axis=false)[end]
    ty.align = [0.5, 1]

    axislines!(parent, scene.px_area)

    LayoutedAxis(parent, scene, xlabel, ylabel, limits)
end


function applylayout(sg::SolvedGridLayout)
    for c in sg.content
        applylayout(c.al)
    end
end

function IRect2D(bbox::BBox)
    l = Int(round(bbox.left))
    r = Int(round(bbox.right))
    t = Int(round(bbox.top))
    b = Int(round(bbox.bottom))
    w = r - l
    h = t - b
    IRect(l, b, w, h)
end

function applylayout(sa::SolvedAxisLayout)
    sa.axis.scene.px_area[] = IRect2D(sa.inner)
end

function BBox(i::Rect{2,Int64})
    BBox(i.origin[1], i.origin[1] + i.widths[1], i.origin[2] + i.widths[2], i.origin[2])
end

function shrinkbymargin(rect, margin)
    IRect((rect.origin .+ margin)..., (rect.widths .- 2 .* margin)...)
end

begin
    scene = Scene(resolution=(600, 600));
    display(scene)
    campixel!(scene);

    la1 = LayoutedAxis(scene)
    la2 = LayoutedAxis(scene)
    la3 = LayoutedAxis(scene)
    la4 = LayoutedAxis(scene)
    la5 = LayoutedAxis(scene)

    lines!(la1.scene, rand(200, 2) .* 100, color=:black, show_axis=false);
    lines!(la2.scene, rand(200, 2) .* 100, color=:blue, show_axis=false);
    lines!(la3.scene, rand(200, 2) .* 100, color=:red, show_axis=false);
    lines!(la4.scene, rand(200, 2) .* 100, color=:orange, show_axis=false);
    lines!(la5.scene, rand(200, 2) .* 100, color=:pink, show_axis=false);

    gl = GridLayout([], 2, 2, [1, 1], [1, 1], 0.01, 0.01)

    gl[2, 1:2] = AxisLayout(BBox(65, 0, 0, 65), la1)
    gl[1, 2] = AxisLayout(BBox(65, 0, 0, 65), la2)

    gl2 = GridLayout([], 2, 2, [0.8, 0.2], [0.2, 0.8], 0.01, 0.01)
    gl2[2, 1] = AxisLayout(BBox(65, 0, 0, 65), la3)
    gl2[1, 1] = AxisLayout(BBox(65, 0, 0, 65), la4)
    gl2[2, 2] = AxisLayout(BBox(65, 0, 0, 65), la5)

    gl[1, 1] = gl2

    sg = outersolve(gl, BBox(shrinkbymargin(pixelarea(scene)[], 30)))
    applylayout(sg)

    on(scene.events.window_area) do area
        sg = outersolve(gl, BBox(shrinkbymargin(pixelarea(scene)[], 30)))
        applylayout(sg)
    end
end
