using Layered
using BenchmarkTools
using Random

struct BBox
    left::Float64
    right::Float64
    top::Float64
    bottom::Float64
end

width(b::BBox) = b.right - b.left
height(b::BBox) = b.bottom - b.top

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

struct SolvedAxis <: Alignable
    inner::BBox
    outer::BBox
end

struct UnsolvedAxis <: Alignable
    decorations::BBox
end

struct SolvedGrid <: Alignable
    bbox::BBox
    content::Vector{SpannedAlignable}
    nrows::Int
    ncols::Int
    xleftcols::Vector{Float64}
    xrightcols::Vector{Float64}
    ytoprows::Vector{Float64}
    ybottomrows::Vector{Float64}
end

struct UnsolvedGrid <: Alignable
    content::Vector{SpannedAlignable}
    nrows::Int
    ncols::Int
    colratios::Vector{Float64}
    rowratios::Vector{Float64}
    colgapfraction::Float64
    rowgapfraction::Float64
end

leftprotrusion(u::UnsolvedAxis) = u.decorations.left
leftprotrusion(s::SolvedAxis) = s.inner.left - s.outer.left
leftprotrusion(sp::SpannedAlignable) = leftprotrusion(sp.al)

function leftprotrusion(ug::UnsolvedGrid)
    leftmosts = filter(x -> isleftmostin(x, ug), ug.content)
    if isempty(leftmosts)
        0.0
    else
        maximum(leftprotrusion.(leftmosts))
    end
end

rightprotrusion(u::UnsolvedAxis) = u.decorations.right
rightprotrusion(s::SolvedAxis) = s.outer.right - s.inner.right
rightprotrusion(sp::SpannedAlignable) = rightprotrusion(sp.al)

function rightprotrusion(ug::UnsolvedGrid)
    rightmosts = filter(x -> isrightmostin(x, ug), ug.content)
    if isempty(rightmosts)
        0.0
    else
        maximum(rightprotrusion.(rightmosts))
    end
end

topprotrusion(u::UnsolvedAxis) = u.decorations.top
topprotrusion(s::SolvedAxis) = s.outer.top - s.inner.top
topprotrusion(sp::SpannedAlignable) = topprotrusion(sp.al)

function topprotrusion(ug::UnsolvedGrid)
    topmosts = filter(x -> istopmostin(x, ug), ug.content)
    if isempty(topmosts)
        0.0
    else
        maximum(topprotrusion.(topmosts))
    end
end

bottomprotrusion(u::UnsolvedAxis) = u.decorations.bottom
bottomprotrusion(s::SolvedAxis) = s.outer.bottom - s.inner.bottom
bottomprotrusion(sp::SpannedAlignable) = bottomprotrusion(sp.al)

function bottomprotrusion(ug::UnsolvedGrid)
    bottommosts = filter(x -> isbottommostin(x, ug), ug.content)
    if isempty(bottommosts)
        0.0
    else
        maximum(bottomprotrusion.(bottommosts))
    end
end

function solve(ug::UnsolvedGrid, bbox::BBox) # when the grid is inside some other grid
    maxcollefts = zeros(ug.ncols)
    maxcolrights = zeros(ug.ncols)
    maxrowtops = zeros(ug.nrows)
    maxrowbottoms = zeros(ug.nrows)

    for c in ug.content
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

    sumcolgaps = maxcolgap * (ug.ncols - 1)
    sumrowgaps = maxrowgap * (ug.nrows - 1)

    # removed prots
    remaininghorizontalspace = width(bbox) - sumcolgaps
    remainingverticalspace = height(bbox) - sumrowgaps

    addedcolgap = ug.colgapfraction * remaininghorizontalspace
    addedrowgap = ug.rowgapfraction * remainingverticalspace

    spaceforcolumns = remaininghorizontalspace - addedcolgap * (ug.ncols - 1)
    spaceforrows = remainingverticalspace - addedrowgap * (ug.nrows - 1)

    colwidths = ug.colratios ./ sum(ug.colratios) .* spaceforcolumns
    rowheights = ug.rowratios ./ sum(ug.rowratios) .* spaceforrows

    colgap = maxcolgap + addedcolgap
    rowgap = maxrowgap + addedrowgap

    # removed leftprot
    xleftcols = [bbox.left + sum(colwidths[1:i-1]) + (i - 1) * colgap for i in 1:ug.ncols]
    xrightcols = xleftcols .+ colwidths

    # removed topprot
    ytoprows = [bbox.top + sum(rowheights[1:i-1]) + (i - 1) * rowgap for i in 1:ug.nrows]
    ybottomrows = ytoprows .+ rowheights

    solvedcontent = SpannedAlignable[]
    for c in ug.content
        ileft = c.sp.cols.start
        iright = c.sp.cols.stop
        itop = c.sp.rows.start
        ibottom = c.sp.rows.stop

        bbox_cell = Main.BBox(
            xleftcols[ileft], xrightcols[iright], ytoprows[itop], ybottomrows[ibottom])

        solved = solve(c.al, bbox_cell)
        push!(solvedcontent, SpannedAlignable(solved, c.sp))
    end

    # solvedcontent = solve.(ug.content)
    SolvedGrid(bbox, solvedcontent, ug.nrows, ug.ncols, xleftcols,
        xrightcols, ytoprows, ybottomrows)
end

function outersolve(ug::UnsolvedGrid, bbox::BBox)
    maxcollefts = zeros(ug.ncols)
    maxcolrights = zeros(ug.ncols)
    maxrowtops = zeros(ug.nrows)
    maxrowbottoms = zeros(ug.nrows)

    for c in ug.content
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

    maxcolgap = maximum(colgaps)
    maxrowgap = maximum(rowgaps)

    sumcolgaps = maxcolgap * (ug.ncols - 1)
    sumrowgaps = maxrowgap * (ug.nrows - 1)

    remaininghorizontalspace = width(bbox) - sumcolgaps - leftprot - rightprot
    remainingverticalspace = height(bbox) - sumrowgaps - topprot - bottomprot

    addedcolgap = ug.colgapfraction * remaininghorizontalspace
    addedrowgap = ug.rowgapfraction * remainingverticalspace

    spaceforcolumns = remaininghorizontalspace - addedcolgap * (ug.ncols - 1)
    spaceforrows = remainingverticalspace - addedrowgap * (ug.nrows - 1)

    colwidths = ug.colratios ./ sum(ug.colratios) .* spaceforcolumns
    rowheights = ug.rowratios ./ sum(ug.rowratios) .* spaceforrows

    colgap = maxcolgap + addedcolgap
    rowgap = maxrowgap + addedrowgap

    xleftcols = [bbox.left + leftprot + sum(colwidths[1:i-1]) + (i - 1) * colgap for i in 1:ug.ncols]
    xrightcols = xleftcols .+ colwidths

    ytoprows = [bbox.top + topprot + sum(rowheights[1:i-1]) + (i - 1) * rowgap for i in 1:ug.nrows]
    ybottomrows = ytoprows .+ rowheights

    solvedcontent = SpannedAlignable[]
    for c in ug.content
        ileft = c.sp.cols.start
        iright = c.sp.cols.stop
        itop = c.sp.rows.start
        ibottom = c.sp.rows.stop

        bbox_cell = Main.BBox(
            xleftcols[ileft], xrightcols[iright], ytoprows[itop], ybottomrows[ibottom])

        solved = solve(c.al, bbox_cell)
        push!(solvedcontent, SpannedAlignable(solved, c.sp))
    end

    # solvedcontent = solve.(ug.content)
    SolvedGrid(bbox, solvedcontent, ug.nrows, ug.ncols, xleftcols,
        xrightcols, ytoprows, ybottomrows)
end

function solve(ua::UnsolvedAxis, innerbbox)
    ol = innerbbox.left - ua.decorations.left
    or = innerbbox.right + ua.decorations.right
    ot = innerbbox.top - ua.decorations.top
    ob = innerbbox.bottom + ua.decorations.bottom
    SolvedAxis(innerbbox, Main.BBox(ol, or, ot, ob))
end

function draw!(layer, g::SolvedGrid, debug=true)
    w = width(g.bbox)
    h = height(g.bbox)
    l = g.bbox.left
    b = g.bbox.bottom
    r = g.bbox.right
    t = g.bbox.top

    if debug
        rect!(layer, Rect(g.bbox)) + Fill("green", 0.1)

        for i in 1:g.ncols
            xleft = g.xleftcols[i]
            xright = g.xrightcols[i]
            line!(layer, Line(P(xleft, b), P(xleft, t)))
            line!(layer, Line(P(xright, b), P(xright, t))) + Stroke("red")
        end

        for i in 1:g.nrows
            ytop = g.ytoprows[i]
            ybottom = g.ybottomrows[i]
            line!(layer, Line(P(l, ytop), P(r, ytop)))
            line!(layer, Line(P(l, ybottom), P(r, ybottom))) + Stroke("red")
        end
    end
    draw!.(layer, g.content, debug)
end

function draw!(layer, sp::SpannedAlignable, debug)
    draw!(layer, sp.al, debug)
end

function draw!(layer, a::SolvedAxis, debug=true)
    if debug
        rect!(layer, a.outer) + Fill("red", 0.1)
    end
    r = rect!(layer, a.inner) + Fill("blue", 0.1)

    txts!(layer, r) do r
        [
            Txt(fraction(rightline(r), 0.5), "y axis 2", a.outer.right - a.inner.right, :c, :t, deg(-90)),
            Txt(fraction(leftline(r), 0.5), "y axis", a.inner.left - a.outer.left, :c, :b, deg(-90)),
            Txt(fraction(topline(r), 0.5), "title", a.inner.top - a.outer.top, :c, :b, deg(0)),
            Txt(fraction(bottomline(r), 0.5), "x axis", a.outer.bottom - a.inner.bottom, :c, :t, deg(0))
        ]
    end
end

function Layered.Rect(bb::Main.BBox)
    center = P(0.5 * (bb.right + bb.left), 0.5 * (bb.top + bb.bottom))
    w = width(bb)
    h = height(bb)
    Layered.Rect(center, w, h, deg(0))
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

function test()

    Random.seed!(1)

    c, tl = canvas(4, 4)
    w = 3.5 * 72
    h = 3.5 * 72
    l = -3.5 / 2 * 72
    b = 3.5 / 2 * 72

    bbox = Main.BBox(l, l + w, b - h, b)

    ua() = UnsolvedAxis(BBox((rand(4) .* 5 .+ 7)...))

    ug = UnsolvedGrid([], 3, 3, [1, 1, 1.0], [1.5, 1.25, 1], 0.1, 0.1)


    ug[1, 1:3] = ua()
    ug[2:3, 1] = ua()


    ug2 = UnsolvedGrid([], 2, 3, [1, 1, 1], [1, 1], 0.1, 0.1)
    ug2[1, 1] = ua()
    ug2[2, 1:2] = ua()
    ug2[2, 3] = ua()
    ug2[1, 2:3] = ua()

    ug[2:3, 2:3] = ug2

    sg = outersolve(ug, bbox)

    draw!(tl, sg, true)

    png(c, "./MakieLayout/MakieLayout/with_placeholders.png", dpi=300)

end; test()
