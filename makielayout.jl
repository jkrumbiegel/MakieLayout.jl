using Random
using PlotUtils
using Makie
using AbstractPlotting
import Showoff
using Printf
using AbstractPlotting: Rect2D
import AbstractPlotting: IRect2D

const BBox = Rect2D{Float64}

left(rect::Rect2D) = minimum(rect)[1]
right(rect::Rect2D) = maximum(rect)[1]

bottom(rect::Rect2D) = minimum(rect)[2]
top(rect::Rect2D) = maximum(rect)[2]

abstract type Side end

struct Left <: Side end
struct Right <: Side end
struct Top <: Side end
struct Bottom <: Side end

Base.getindex(bbox::Rect2D, ::Left) = left(bbox)
Base.getindex(bbox::Rect2D, ::Right) = right(bbox)
Base.getindex(bbox::Rect2D, ::Bottom) = bottom(bbox)
Base.getindex(bbox::Rect2D, ::Top) = top(bbox)

mutable struct LayoutedAxis
    parent::Scene
    scene::Scene
    xlabel::Node{String}
    ylabel::Node{String}
    limits::Node{FRect2D} # these should steer the camera, not used yet
end

width(rect::Rect2D) = right(rect) - left(rect)
height(rect::Rect2D) = top(rect) - bottom(rect)


function BBox(left::Number, right::Number, top::Number, bottom::Number)
    mini = (left, bottom)
    maxi = (right, top)
    return BBox(mini, maxi .- mini)
end

function IRect2D(bbox::Rect2D)
    return IRect2D(
        round.(Int, minimum(bbox)),
        round.(Int, widths(bbox))
    )
end

struct RowCols{T <: Union{Number, Vector{Float64}}}
    lefts::T
    rights::T
    tops::T
    bottoms::T
end

function RowCols(ncols::Int, nrows::Int)
    return RowCols(
        zeros(ncols),
        zeros(ncols),
        zeros(nrows),
        zeros(nrows)
    )
end

Base.getindex(rowcols::RowCols, ::Left) = rowcols.lefts
Base.getindex(rowcols::RowCols, ::Right) = rowcols.rights
Base.getindex(rowcols::RowCols, ::Top) = rowcols.tops
Base.getindex(rowcols::RowCols, ::Bottom) = rowcols.bottoms

"""
    eachside(f)
Calls f over all sides (Left, Right, Top, Bottom), and creates a BBox from the result of f(side)
"""
function eachside(f)
    return BBox(map(f, (Left(), Right(), Top(), Bottom()))...)
end

"""
mapsides(
       f, first::Union{Rect2D, RowCols}, rest::Union{Rect2D, RowCols}...
   )::BBox
Maps f over all sides of the rectangle like arguments.
e.g.
```
mapsides(BBox(left, right, top, bottom)) do side::Side, side_val::Number
    return ...
end::BBox
```
"""
function mapsides(
        f, first::Union{Rect2D, RowCols}, rest::Union{Rect2D, RowCols}...
    )
    return eachside() do side
        f(side, getindex.((first, rest...), (side,))...)
    end
end

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
struct SpannedAlignable{T <: Alignable}
    al::T
    sp::Span
end
function side_indices(c::SpannedAlignable)
    return RowCols(
        c.sp.cols.start,
        c.sp.cols.stop,
        c.sp.rows.start,
        c.sp.rows.stop,
    )
end

"""
These functions tell whether an object in a grid touches the left, top, etc. border
of the grid. This means that it is relevant for the grid's own protrusion on that side.
"""
ismostin(sp::SpannedAlignable, grid, ::Left) = sp.sp.cols.start == 1
ismostin(sp::SpannedAlignable, grid, ::Right) = sp.sp.cols.stop == grid.ncols
ismostin(sp::SpannedAlignable, grid, ::Bottom) = sp.sp.rows.stop == grid.nrows
ismostin(sp::SpannedAlignable, grid, ::Top) = sp.sp.cols.start == 1

isleftmostin(sp::SpannedAlignable, grid) = ismostin(sp, grid, Left())
isrightmostin(sp::SpannedAlignable, grid) = ismostin(sp, grid, Right())
isbottommostin(sp::SpannedAlignable, grid) = ismostin(sp, grid, Bottom())
istopmostin(sp::SpannedAlignable, grid) = ismostin(sp, grid, Top())

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
    grid::RowCols{Vector{Float64}}
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
leftprotrusion(x) = protrusion(x, Left())
rightprotrusion(x) = protrusion(x, Right())
bottomprotrusion(x) = protrusion(x, Bottom())
topprotrusion(x) = protrusion(x, Top())

protrusion(u::AxisLayout, side::Side) = u.decorations[side]
protrusion(sp::SpannedAlignable, side::Side) = protrusion(sp.al, side)

function protrusion(gl::GridLayout, side::Side)
    return mapreduce(max, gl.content, init = 0.0) do elem
        # we use only objects that stick out on this side
        # And from those we use the maximum protrusion
        ismostin(elem, gl, side) ? protrusion(elem, side) : 0.0
    end
end

protrusion(s::SolvedAxisLayout, ::Left) = left(s.inner) - left(s.outer)
function protrusion(s::SolvedAxisLayout, side::Side)
    return s.outer[side] - s.inner[side]
end

"""
This function solves a grid layout such that the "important lines" fit exactly
into a given bounding box. This means that the protrusions of all objects inside
the grid are not taken into account. This is needed if the grid is itself placed
inside another grid.
"""
function solve(gl::GridLayout, bbox::BBox)

    # first determine how big the protrusions on each side of all columns and rows are
    maxgrid = RowCols(gl.ncols, gl.nrows)
    # go through all the layout objects placed in the grid
    for c in gl.content
        idx_rect = side_indices(c)
        mapsides(idx_rect, maxgrid) do side, idx, grid
            grid[idx] = max(grid[idx], protrusion(c.al, side))
        end
    end
    # compute what size the gaps between rows and columns need to be
    colgaps = maxgrid.lefts[2:end] .+ maxgrid.rights[1:end-1]
    rowgaps = maxgrid.tops[2:end] .+ maxgrid.bottoms[1:end-1]

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
    xleftcols = [left(bbox) + sum(colwidths[1:i-1]) + (i - 1) * colgap for i in 1:gl.ncols]
    xrightcols = xleftcols .+ colwidths

    # compute the y values for all top and bottom row boundaries
    ytoprows = [top(bbox) - sum(rowheights[1:i-1]) - (i - 1) * rowgap for i in 1:gl.nrows]
    ybottomrows = ytoprows .- rowheights

    # now we can solve the content thats inside the grid because we know where each
    # column and row is placed, how wide it is, etc.
    # note that what we did at the top was determine the protrusions of all grid content,
    # but we know the protrusions before we know how much space each plot actually has
    # because the protrusions should be static (like tick labels etc don't change size with the plot)

    gridboxes = RowCols(
        xleftcols, xrightcols,
        ytoprows, ybottomrows
    )
    solvedcontent = map(gl.content) do c
        idx_rect = side_indices(c)
        bbox_cell = mapsides(idx_rect, gridboxes) do side, idx, gridside
            gridside[idx]
        end
        solved = solve(c.al, bbox_cell)
        return SpannedAlignable(solved, c.sp)
    end
    # return a solved grid layout in which all objects are also solved layout objects
    return SolvedGridLayout(
        bbox, solvedcontent,
        gl.nrows, gl.ncols,
        gridboxes
    )
end



"""
This function solves a grid layout so that it fits exactly inside a bounding box.
Exactly means that the protrusions of all other objects inside this grid layout
also have to fit into the bounding box. This is needed if the grid is the outermost
object in the layout, the bounding box would then be the scene boundary.
"""
function outersolve(gl::GridLayout, bbox::BBox)
    maxgrid = RowCols(gl.ncols, gl.nrows)
    for c in gl.content
        idx_rect = side_indices(c)
        mapsides(idx_rect, maxgrid) do side, idx, grid
            grid[idx] = max(grid[idx], protrusion(c.al, side))
        end
    end

    topprot = maxgrid.tops[1]
    bottomprot = maxgrid.bottoms[end]
    leftprot = maxgrid.lefts[1]
    rightprot = maxgrid.rights[end]

    colgaps = maxgrid.lefts[2:end] .+ maxgrid.rights[1:end-1]
    rowgaps = maxgrid.tops[2:end] .+ maxgrid.bottoms[1:end-1]

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

    xleftcols = map(1:gl.ncols) do i
        left(bbox) + leftprot + sum(colwidths[1:i-1]) + (i - 1) * colgap
    end
    xrightcols = xleftcols .+ colwidths

    ytoprows = map(1:gl.nrows) do i
        top(bbox) - topprot - sum(rowheights[1:i-1]) - (i - 1) * rowgap
    end

    ybottomrows = ytoprows .- rowheights
    gridboxes = RowCols(
        xleftcols, xrightcols,
        ytoprows, ybottomrows
    )
    solvedcontent = map(gl.content) do c
        idx_rect = side_indices(c)
        bbox_cell = mapsides(idx_rect, gridboxes) do side, idx, gridside
            gridside[idx]
        end
        solved = solve(c.al, bbox_cell)
        return SpannedAlignable(solved, c.sp)
    end
    # solvedcontent = solve.(gl.content)
    SolvedGridLayout(
        bbox, solvedcontent, gl.nrows, gl.ncols,
        gridboxes
    )
end



function solve(ua::AxisLayout, innerbbox)
    bbox = mapsides(innerbbox, ua.decorations) do side, iside, decside
        op = side isa Union{Left, Top} ? (-) : (+)
        return op(iside, decside)
    end
    SolvedAxisLayout(innerbbox, bbox, ua.axis)
end

const Indexables = Union{UnitRange, Int, Colon}

"""
This function allows indexing syntax to add a layout object to a grid.
You can do:

grid[1, 1] = obj
grid[1, :] = obj
grid[1:3, 2:5] = obj

and all combinations of the above
"""
function Base.setindex!(g, a::Alignable, rows::Indexables, cols::Indexables)
    if rows isa Int
        rows = rows:rows
    elseif rows isa Colon
        rows = 1:g.nrows
    end
    if cols isa Int
        cols = cols:cols
    elseif cols isa Colon
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
    lines!(scene, points, linewidth = 2, show_axis = false)
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

# struct LimitCamera <: AbstractCamera end

function LayoutedAxis(parent::Scene)
    scene = Scene(parent, Node(IRect(0, 0, 100, 100)), center=false)
    limits = Node(FRect(0, 0, 100, 100))
    xlabel = Node("x label")
    ylabel = Node("y label")

    disconnect!(camera(scene))

    e = events(scene)

    cam = camera(scene)
    on(cam, e.scroll) do x
        # @extractvalue cam (zoomspeed, zoombutton, area)
        zoomspeed = 0.10f0
        zoombutton = nothing
        zoom = Float32(x[2])
        if zoom != 0 && ispressed(scene, zoombutton) && AbstractPlotting.is_mouseinside(scene)
            pa = pixelarea(scene)[]

            # don't let z go negative
            z = max(0.1f0, 1f0 + (zoom * zoomspeed))

            # limits[] = FRect(limits[].origin..., (limits[].widths .* 0.99)...)
            mp_fraction = (Vec2f0(e.mouseposition[]) - minimum(pa)) ./ widths(pa)

            mp_data = limits[].origin .+ mp_fraction .* limits[].widths

            xorigin = limits[].origin[1]
            yorigin = limits[].origin[2]

            xwidth = limits[].widths[1]
            ywidth = limits[].widths[2]
            newxwidth = xwidth * z
            newywidth = ywidth * z

            newxorigin = xorigin + mp_fraction[1] * (xwidth - newxwidth)
            newyorigin = yorigin + mp_fraction[2] * (ywidth - newywidth)

            if AbstractPlotting.ispressed(scene, AbstractPlotting.Keyboard.x)
                limits[] = FRect(newxorigin, yorigin, newxwidth, ywidth)
            elseif AbstractPlotting.ispressed(scene, AbstractPlotting.Keyboard.y)
                limits[] = FRect(xorigin, newyorigin, xwidth, newywidth)
            else
                limits[] = FRect(newxorigin, newyorigin, newxwidth, newywidth)
            end
        end
        return
    end

    cam = AbstractPlotting.PixelCamera()
    cameracontrols!(scene, cam)
    ###############################


    ticksnode = Node(Point2f0[])
    ticks = linesegments!(
        parent, ticksnode, linewidth = 2, show_axis = false
    )[end]

    # the algorithm from above seems to not give more than 7 ticks with the step sizes I chose
    nmaxticks = 7

    xticklabelnodes = [Node("0") for i in 1:nmaxticks]
    xticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    xticklabels = map(1:nmaxticks) do i
        text!(
            parent,
            xticklabelnodes[i],
            position = xticklabelposnodes[i],
            align = (:center, :top),
            textsize = 20,
            show_axis = false
        )[end]
    end

    yticklabelnodes = [Node("0") for i in 1:nmaxticks]
    yticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    yticklabels = map(1:nmaxticks) do i
        text!(
            parent,
            yticklabelnodes[i],
            position = yticklabelposnodes[i],
            align = (:center, :bottom),
            rotation = pi/2,
            textsize = 20,
            show_axis = false
        )[end]
    end

    on(camera(scene), pixelarea(scene), limits) do pxa, lims

        nearclip = -10_000f0
        farclip = 10_000f0

        limox, limoy = Float32.(lims.origin)
        limw, limh = Float32.(widths(lims))
        l, b = Float32.(pxa.origin)
        w, h = Float32.(widths(pxa))
        # projection = AbstractPlotting.orthographicprojection(0f0, w * 2f0, 0f0, h, nearclip, farclip)
        projection = AbstractPlotting.orthographicprojection(limox, limox + limw, limoy, limoy + limh, nearclip, farclip)
        camera(scene).projection[] = projection
        camera(scene).projectionview[] = projection

        # pxa = scene.px_area[]
        px_aspect = pxa.widths[1] / pxa.widths[2]

        # @printf("cam %.1f, %.1f, %.1f, %.1f\n", a.origin..., a.widths...)
        # @printf("pix %.1f, %.1f, %.1f, %.1f\n", pxa.origin..., pxa.widths...)

        width = lims.widths[1]
        # width = px_aspect > 1 ? a.widths[1] / px_aspect : a.widths[1]
        xrange = (lims.origin[1], lims.origin[1] + width)


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

        # height = px_aspect < 1 ? a.widths[2] * px_aspect : a.widths[2]
        height = lims.widths[2]
        yrange = (lims.origin[2], lims.origin[2] + height)


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
            [xtickends; ytickends]
        )))
    end

    labelgap = 50

    xlabelpos = lift(scene.px_area) do a
        Point2(a.origin[1] + a.widths[1] / 2, a.origin[2] - labelgap)
    end

    ylabelpos = lift(scene.px_area) do a
        Point2(a.origin[1] - labelgap, a.origin[2] + a.widths[2] / 2)
    end

    tx = text!(
        parent, xlabel, textsize = 20, position = xlabelpos, show_axis = false
    )[end]
    tx.align = [0.5, 1]
    ty = text!(
        parent, ylabel, textsize = 20,
        position = ylabelpos, rotation = pi/2, show_axis = false
    )[end]
    ty.align = [0.5, 0]

    axislines!(parent, scene.px_area)

    LayoutedAxis(parent, scene, xlabel, ylabel, limits)
end


function applylayout(sg::SolvedGridLayout)
    for c in sg.content
        applylayout(c.al)
    end
end

function applylayout(sa::SolvedAxisLayout)
    sa.axis.scene.px_area[] = IRect2D(sa.inner)
end

function shrinkbymargin(rect, margin)
    IRect((rect.origin .+ margin), (rect.widths .- 2 .* margin))
end

function linkxaxes!(a::LayoutedAxis, b::LayoutedAxis)
    on(a.limits) do alim
        blim = b.limits[]

        ao = alim.origin[1]
        bo = blim.origin[1]
        aw = alim.widths[1]
        bw = blim.widths[1]

        if ao != bo || aw != bw
            b.limits[] = FRect(ao, blim.origin[2], aw, blim.widths[2])
        end
    end

    on(b.limits) do blim
        alim = a.limits[]

        ao = alim.origin[1]
        bo = blim.origin[1]
        aw = alim.widths[1]
        bw = blim.widths[1]

        if ao != bo || aw != bw
            a.limits[] = FRect(bo, alim.origin[2], bw, alim.widths[2])
        end
    end
end

function linkyaxes!(a::LayoutedAxis, b::LayoutedAxis)
    on(a.limits) do alim
        blim = b.limits[]

        ao = alim.origin[2]
        bo = blim.origin[2]
        aw = alim.widths[2]
        bw = blim.widths[2]

        if ao != bo || aw != bw
            b.limits[] = FRect(blim.origin[1], ao, blim.widths[1], aw)
        end
    end

    on(b.limits) do blim
        alim = a.limits[]

        ao = alim.origin[2]
        bo = blim.origin[2]
        aw = alim.widths[2]
        bw = blim.widths[2]

        if ao != bo || aw != bw
            a.limits[] = FRect(alim.origin[1], bo, alim.widths[1], bw)
        end
    end
end

begin
    scene = Scene(resolution=(600, 600));
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
    scatter!(la3.scene, rand(200, 2) .* 100, markersize=3, color=:red, show_axis=false)
    lines!(la4.scene, rand(200, 2) .* 100, color=:orange, show_axis=false)
    lines!(la5.scene, rand(200, 2) .* 100, color=:pink, show_axis=false)
    update!(scene)

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
    # @profiler wait(screen)
end
