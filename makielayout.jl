using Random
using Animations
using PlotUtils
using Makie
import Showoff
using Printf

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
    limits::Node{FRect2D} # these should steer the camera, not used yet
end

width(b::BBox) = b.right - b.left
height(b::BBox) = b.top - b.bottom

abstract type Alignable end

"""
Used to specify space that is occupied in a grid. Like 1:1|1:1 for the first square,
or 2:3|1:4 for a rect over the 2nd and 3rd row and the first four columns.
"""
struct Span
    rows::UnitRange{Int64}
    cols::UnitRange{Int64}
end

"""
An object that can be aligned that also specifies how much space it occupies in
a grid via its span.
"""
struct SpannedAlignable{T<:Alignable}
    al::T
    sp::Span
end

"""
These functions tell whether an object in a grid touches the left, top, etc. border
of the grid. This means that it is relevant for the grid's own protrusion on that side.
"""

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

"""
All the protrusion functions calculate how much stuff "sticks out" of a layoutable object.
This is so that collisions are avoided, while what is actually aligned is the
"important" edges of the layout objects.
"""

leftprotrusion(u::AxisLayout) = u.decorations.left
leftprotrusion(s::SolvedAxisLayout) = s.inner.left - s.outer.left
leftprotrusion(sp::SpannedAlignable) = leftprotrusion(sp.al)

function leftprotrusion(gl::GridLayout)
    # any objects that stick out on this side?
    leftmosts = filter(x -> isleftmostin(x, gl), gl.content)
    if isempty(leftmosts)
        # no protrusion
        0.0
    else
        # use the biggest protrusion of all objects that stick out
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

"""
This function solves a grid layout such that the "important lines" fit exactly
into a given bounding box. This means that the protrusions of all objects inside
the grid are not taken into account. This is needed if the grid is itself placed
inside another grid.
"""
function solve(gl::GridLayout, bbox::BBox)

    # first determine how big the protrusions on each side of all columns and rows are
    maxcollefts = zeros(gl.ncols)
    maxcolrights = zeros(gl.ncols)
    maxrowtops = zeros(gl.nrows)
    maxrowbottoms = zeros(gl.nrows)

    # go through all the layout objects placed in the grid
    for c in gl.content
        # determine the rows and columns where they start and end
        ileft = c.sp.cols.start
        iright = c.sp.cols.stop
        itop = c.sp.rows.start
        ibottom = c.sp.rows.stop

        # increase the protrusions of those columns and rows if they are larger than
        # what they were before.
        # this way the gap between two columns is at least the largest protrusion
        # sticking in from the left plus the largest sticking in from the right
        maxcollefts[ileft] = max(maxcollefts[ileft], leftprotrusion(c.al))
        maxcolrights[iright] = max(maxcolrights[iright], rightprotrusion(c.al))
        maxrowtops[itop] = max(maxrowtops[itop], topprotrusion(c.al))
        maxrowbottoms[ibottom] = max(maxrowbottoms[ibottom], bottomprotrusion(c.al))
    end

    # compute what size the gaps between rows and columns need to be
    colgaps = maxcollefts[2:end] .+ maxcolrights[1:end-1]
    rowgaps = maxrowtops[2:end] .+ maxrowbottoms[1:end-1]

    # determine the biggest gap
    # using the biggest gap size for all gaps will make the layout more even, but one
    # could make this aspect customizable, because it might waste space
    maxcolgap = maximum(colgaps)
    maxrowgap = maximum(rowgaps)

    # determine the vertical and horizontal space needed just for the gaps
    # again, the gaps are what the protrusions stick into, so they are not actually "empty"
    # depending on what sticks out of the plots
    sumcolgaps = maxcolgap * (gl.ncols - 1)
    sumrowgaps = maxrowgap * (gl.nrows - 1)

    # compute what space remains for the inner parts of the plots
    remaininghorizontalspace = width(bbox) - sumcolgaps
    remainingverticalspace = height(bbox) - sumrowgaps

    # compute how much gap to add, in case e.g. labels are too close together
    # this is given as a fraction of the space used for the inner parts of the plots
    # so far, but maybe this should just be an absolute pixel value so it doesn't change
    # when resizing the window
    addedcolgap = gl.colgapfraction * remaininghorizontalspace
    addedrowgap = gl.rowgapfraction * remainingverticalspace

    # compute the actual space available for the rows and columns (plots without protrusions)
    spaceforcolumns = remaininghorizontalspace - addedcolgap * (gl.ncols - 1)
    spaceforrows = remainingverticalspace - addedrowgap * (gl.nrows - 1)

    # compute the column widths and row heights using the specified row and column ratios
    colwidths = gl.colratios ./ sum(gl.colratios) .* spaceforcolumns
    rowheights = gl.rowratios ./ sum(gl.rowratios) .* spaceforrows

    # this is the vertical / horizontal space between the inner lines of all plots
    colgap = maxcolgap + addedcolgap
    rowgap = maxrowgap + addedrowgap

    # compute the x values for all left and right column boundaries
    xleftcols = [bbox.left + sum(colwidths[1:i-1]) + (i - 1) * colgap for i in 1:gl.ncols]
    xrightcols = xleftcols .+ colwidths

    # compute the y values for all top and bottom row boundaries
    ytoprows = [bbox.top - sum(rowheights[1:i-1]) - (i - 1) * rowgap for i in 1:gl.nrows]
    ybottomrows = ytoprows .- rowheights

    # now we can solve the content thats inside the grid because we know where each
    # column and row is placed, how wide it is, etc.
    # note that what we did at the top was determine the protrusions of all grid content,
    # but we know the protrusions before we know how much space each plot actually has
    # because the protrusions should be static (like tick labels etc don't change size with the plot)
    solvedcontent = SpannedAlignable[]
    for c in gl.content
        # determine in which rows and columns the content object lies
        ileft = c.sp.cols.start
        iright = c.sp.cols.stop
        itop = c.sp.rows.start
        ibottom = c.sp.rows.stop

        # make a bounding box with the x and y values of the columns and rows
        bbox_cell = Main.BBox(
            xleftcols[ileft], xrightcols[iright], ytoprows[itop], ybottomrows[ibottom])

        # solve the child object's layout
        # this is what makes nested grids possible, because they just get solved from the top
        # all the way down
        solved = solve(c.al, bbox_cell)

        # add the solved object to the list of solved child objects that gets saved in the solved layout
        push!(solvedcontent, SpannedAlignable(solved, c.sp))
    end

    # return a solved grid layout in which all objects are also solved layout objects
    SolvedGridLayout(bbox, solvedcontent, gl.nrows, gl.ncols, xleftcols,
        xrightcols, ytoprows, ybottomrows)
end

"""
This function solves a grid layout so that it fits exactly inside a bounding box.
Exactly means that the protrusions of all other objects inside this grid layout
also have to fit into the bounding box. This is needed if the grid is the outermost
object in the layout, the bounding box would then be the scene boundary.
"""
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

"""
This function allows indexing syntax to add a layout object to a grid.
You can do:

grid[1, 1] = obj
grid[1, :] = obj
grid[1:3, 2:5] = obj

and all combinations of the above
"""
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

"""
A cheaper function that tries to come up with usable tick locations for a given value range
"""
function locateticks(xmin, xmax)
    # whats the distance?
    d = xmax - xmin
    # which order of magnitude is the distance in?
    ex = log10(d)
    # round the exponent to the closest one
    exrounded = round(ex)
    # this factor is used so we can find integer steps that then map back to
    # nice numbers in the given value range
    factor = 1 / 10 ^ (exrounded - 1)

    # minimum needs to be at least the lower value times the scaling factor
    xminf = ceil(xmin * factor)
    # maximum needs to be at most the higher value times the scaling factor
    xmaxf = floor(xmax * factor)

    # xminf and xmaxf are now both integers that are in an order of magnitude around ten steps apart
    df = xmaxf - xminf

    # step sizes we like
    steps = [5, 4, 2, 1]

    # from the highest to the lowest step size, choose the first that fits at least
    # two times between the end values (gives three ticks including the end value)
    for s in steps
        n, remainder = divrem(df, s)
        if n >= 2
            rang = 1:n
            # calculate the ticks by dividing with the factor from above
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

    # the algorithm from above seems to not give more than 7 ticks with the step sizes I chose
    nmaxticks = 7

    xticklabelnodes = [Node("0") for i in 1:nmaxticks]
    xticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    xticklabels = [text!(parent,
        xticklabelnodes[i],
        position = xticklabelposnodes[i],
        align = (:center, :top),
        textsize=20)[end]
            for i in 1:nmaxticks]

    yticklabelnodes = [Node("0") for i in 1:nmaxticks]
    yticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    yticklabels = [text!(parent,
        yticklabelnodes[i],
        position = yticklabelposnodes[i],
        align = (:center, :bottom),
        rotation = pi/2,
        textsize=20)[end]
            for i in 1:nmaxticks]

    on(cam.area) do a

        pxa = scene.px_area[]
        px_aspect = pxa.widths[1] / pxa.widths[2]

        # @printf("cam %.1f, %.1f, %.1f, %.1f\n", a.origin..., a.widths...)
        # @printf("pix %.1f, %.1f, %.1f, %.1f\n", pxa.origin..., pxa.widths...)

        width = px_aspect > 1 ? a.widths[1] / px_aspect : a.widths[1]
        xrange = (a.origin[1], a.origin[1] + width)


        if width == 0 || !isfinite(xrange[1]) || !isfinite(xrange[2])
            return
        end

        xtickvals = locateticks(xrange...)
        # xtickvals, vminbest, vmaxbest = optimize_ticks(xrange...)


        # this code here tries to transform between values given in pixels of the
        # scene and the camera area, but this is incorrect right now and everything
        # should just be determined by the now unused limits that are saved in the
        # LayoutedAxis object
        xfractions = (xtickvals .- xrange[1]) ./ width
        xrange_scene = (pxa.origin[1], pxa.origin[1] + pxa.widths[1])
        width_scene = xrange_scene[2] - xrange_scene[1]
        xticks_scene = xrange_scene[1] .+ width_scene .* xfractions
        ticksize = 10 # px
        y = pxa.origin[2]
        xtickstarts = [Point(x, y) for x in xticks_scene]
        xtickends = [t + Point(0.0, -ticksize) for t in xtickstarts]

        height = px_aspect < 1 ? a.widths[2] * px_aspect : a.widths[2]
        yrange = (a.origin[2], a.origin[2] + height)


        ytickvals = locateticks(yrange...)
        # ytickvals, vminbest, vmaxbest = optimize_ticks(yrange...)
        yfractions = (ytickvals .- yrange[1]) ./ height
        yrange_scene = (pxa.origin[2], pxa.origin[2] + pxa.widths[2])
        height_scene = yrange_scene[2] - yrange_scene[1]
        yticks_scene = yrange_scene[1] .+ height_scene .* yfractions
        ticksize = 10 # px
        x = pxa.origin[1]
        ytickstarts = [Point(x, y) for y in yticks_scene]
        ytickends = [t + Point(-ticksize, 0.0) for t in ytickstarts]


        # set and position tick labels
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

        ytickstrings = Showoff.showoff(ytickvals, :plain)
        nyticks = length(ytickvals)
        for i in 1:nmaxticks
            if i <= nyticks
                yticklabelnodes[i][] = ytickstrings[i]
                yticklabelposnodes[i][] = ytickends[i] + Point(-10.0, 0.0)
                yticklabels[i].visible = true
            else
                yticklabels[i].visible = false
            end
        end

        # set tick mark positions
        ticksnode[] = collect(Iterators.flatten(zip(
           [xtickstarts; ytickstarts],
           [xtickends; ytickends])))
    end

    labelgap = 50

    xlabelpos = lift(scene.px_area) do a
        Point2(a.origin[1] + a.widths[1] / 2, a.origin[2] - labelgap)
    end

    ylabelpos = lift(scene.px_area) do a
        Point2(a.origin[1] - labelgap, a.origin[2] + a.widths[2] / 2)
    end

    tx = text!(parent, xlabel, textsize=20, position=xlabelpos, show_axis=false)[end]
    tx.align = [0.5, 1]
    ty = text!(parent, ylabel, textsize=20, position=ylabelpos, rotation=pi/2, show_axis=false)[end]
    ty.align = [0.5, 0]

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

    # lines!(la1.scene, rand(200, 2) .* 100, color=:black, show_axis=false)
    img = rand(100, 100)
    image!(la1.scene, img, show_axis=false)
    lines!(la2.scene, rand(200, 2) .* 100, color=:blue, show_axis=false)
    scatter!(la3.scene, rand(200, 2) .* 100, markersize=3, color=:red, show_axis=false)
    lines!(la4.scene, rand(200, 2) .* 100, color=:orange, show_axis=false)
    lines!(la5.scene, rand(200, 2) .* 100, color=:pink, show_axis=false)

    gl = GridLayout([], 2, 2, [1, 1], [1, 1], 0.01, 0.01)

    gl[2, 1:2] = AxisLayout(BBox(75, 0, 0, 75), la1)
    gl[1, 2] = AxisLayout(BBox(75, 0, 0, 75), la2)

    gl2 = GridLayout([], 2, 2, [0.8, 0.2], [0.2, 0.8], 0.01, 0.01)
    gl2[2, 1] = AxisLayout(BBox(75, 0, 0, 75), la3)
    gl2[1, 1] = AxisLayout(BBox(75, 0, 0, 75), la4)
    gl2[2, 2] = AxisLayout(BBox(75, 0, 0, 75), la5)

    gl[1, 1] = gl2

    sg = outersolve(gl, BBox(shrinkbymargin(pixelarea(scene)[], 30)))
    applylayout(sg)

    # when the scene is resized, apply the outersolve'd outermost grid layout
    # this recursively updates all layout objects that are contained in the grid
    on(scene.events.window_area) do area
        sg = outersolve(gl, BBox(shrinkbymargin(pixelarea(scene)[], 30)))
        applylayout(sg)
    end
end
