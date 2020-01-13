const BBox = Rect2D{Float32}

const Optional{T} = Union{Nothing, T}

struct RectSides{T<:Real}
    left::T
    right::T
    bottom::T
    top::T
end

abstract type Side end

struct Left <: Side end
struct Right <: Side end
struct Top <: Side end
struct Bottom <: Side end

# for protrusion content:
struct TopLeft <: Side end
struct TopRight <: Side end
struct BottomLeft <: Side end
struct BottomRight <: Side end

struct Inner <: Side end
struct Outer <: Side end

abstract type GridDir end
struct Col <: GridDir end
struct Row <: GridDir end

struct RowCols{T <: Union{Number, Vector{Float64}}}
    lefts::T
    rights::T
    tops::T
    bottoms::T
end


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
mutable struct GridContent{G, T} # G should be GridLayout but can't be used before definition
    parent::Optional{G}
    al::T
    sp::Span
    side::Side
    needs_update::Node{Bool}
    protrusions_handle::Optional{Function}
    computedsize_handle::Optional{Function}
end

abstract type AlignMode end

struct Inside <: AlignMode end
struct Outside <: AlignMode
    padding::RectSides{Float32}
end
Outside() = Outside(0f0)
Outside(padding::Real) = Outside(RectSides{Float32}(padding, padding, padding, padding))
Outside(left::Real, right::Real, bottom::Real, top::Real) =
    Outside(RectSides{Float32}(left, right, bottom, top))

abstract type ContentSize end
abstract type GapSize <: ContentSize end

struct Auto <: ContentSize
    trydetermine::Bool # false for determinable size content that should be ignored
    ratio::Float64 # float ratio in case it's not determinable

    Auto(trydetermine::Bool = true, ratio::Real = 1.0) = new(trydetermine, ratio)
end
Auto(ratio::Real) = Auto(true, ratio)

struct Fixed <: GapSize
    x::Float64
end
struct Relative <: GapSize
    x::Float64
end
struct Aspect <: ContentSize
    index::Int
    ratio::Float64
end

mutable struct LayoutNodes{T, G} # G again GridLayout
    suggestedbbox::Node{BBox}
    protrusions::Node{RectSides{Float32}}
    computedsize::Node{NTuple{2, Optional{Float32}}}
    autosize::Node{NTuple{2, Optional{Float32}}}
    computedbbox::Node{BBox}
    gridcontent::Optional{GridContent{G, T}} # the connecting link to the gridlayout
end

mutable struct GridLayout
    content::Vector{GridContent}
    nrows::Int
    ncols::Int
    rowsizes::Vector{ContentSize}
    colsizes::Vector{ContentSize}
    addedrowgaps::Vector{GapSize}
    addedcolgaps::Vector{GapSize}
    alignmode::AlignMode
    equalprotrusiongaps::Tuple{Bool, Bool}
    needs_update::Node{Bool}
    block_updates::Bool
    layoutnodes::LayoutNodes
    attributes::Attributes
    _update_func_handle::Optional{Function} # stores a reference to the result of on(obs)

    function GridLayout(
        content, nrows, ncols, rowsizes, colsizes,
        addedrowgaps, addedcolgaps, alignmode, equalprotrusiongaps, needs_update,
        layoutnodes, attributes)

        gl = new(content, nrows, ncols, rowsizes, colsizes,
            addedrowgaps, addedcolgaps, alignmode, equalprotrusiongaps,
            needs_update, false, layoutnodes, attributes, nothing)

        validategridlayout(gl)

        # attach_parent!(gl, parent)

        # on(needs_update) do update
        #     request_update(gl)
        # end

        gl
    end
end


struct AxisAspect
    aspect::Float32
end

struct DataAspect end

"An abstract type representing ticks."
abstract type Ticks end

"""
    AutoLinearTicks(idealtickdistance::Float32)

This is a simple tick finding function which takes in an ideal tick distance
**in pixels**.
"""
struct AutoLinearTicks <: Ticks
    idealtickdistance::Float32
end

AutoLinearTicks(num::Real) = AutoLinearTicks(Float32(num))


"""
    AutoOptimizedTicks(; kwargs...)

This is basically Wilkinson's ad-hoc scoring method that tries to balance
tight fit around the data, optimal number of ticks, and simple numbers.

This is the function which Plots.jl and Makie.jl use by default.

## Keyword Arguments

$(FIELDS)

## Mathematical details

Wilkinson’s optimization function is defined as the sum of three
components. If the user requests m labels and a possible labeling has
k labels, then the components are `simplicity`, `coverage` and `granularity`.

These components are defined as follows:
```math
\\begin{aligned}
  &\\text{simplicity} = 1 - \\frac{i}{|Q|} + \\frac{v}{|Q|}\\\\
  &\\text{coverage}   = \\frac{x_{max} - x_{min}}{\\mathrm{label}_{max} - \\mathrm{label}_{min}}\\\\
  &\\text{granularity}= 1 - \\frac{\\left|k - m\\right|}{m}
\\end{aligned}
```

and the variables here are:

*  `q`: element of `Q`.
*  `i`: index of `q` in `Q`.
*  `v`: 1 if label range includes 0, 0 otherwise.

"""
Base.@kwdef struct AutoOptimizedTicks <: Ticks

    "Determines whether to extend tick computation.  Defaults to `false`."
    extend_ticks::Bool = false
    "True if no ticks should be outside `[x_min, x_max]`.  Defaults to `true`."
    strict_span::Bool = true

    """
    A distribution of nice numbers from which labellings are sampled.
    Stored in the form `(number, score)`.
    """
    Q = [(1.0,1.0), (5.0, 0.9), (2.0, 0.7), (2.5, 0.5), (3.0, 0.2)]

    "The minimum number of ticks."
    k_min::Int   = 2
    "The maximum number of ticks."
    k_max::Int   = 10
    "The ideal number of ticks."
    k_ideal::Int = 5

    """
    Encourages returning roughly the number of labels requested.
    """
    granularity_weight::Float64 = 1/4

    """
    Encourages nicer labeling sequences by preferring step sizes that
    appear earlier in Q.

    Also rewards labelings that include 0 as a way to ground the sequence.
    """
    simplicity_weight::Float64 = 1/6

    """
    Encourages labelings that do not extend far beyond
    the range of the data, penalizing unnecessary whitespace.
    """
    coverage_weight::Float64 = 1/3

    """
    Encourages labellings to produce nice ranges.
    """
    niceness_weight::Float64 = 1/4

end

"""
    ManualTicks(values::Vector{Float32}, labels::Vector{String})

This is used to define manual ticks.
Tick values must be within the axis limits.
"""
struct ManualTicks <: Ticks
    values::Vector{Float32}
    labels::Vector{String}
end

struct AxisContent{T}
    content::T
    attributes::Attributes
end

mutable struct LineAxis
    parent::Scene
    protrusion::Node{Float32}
    attributes::Attributes
    decorations::Dict{Symbol, Any}
    tickpositions::Node{Vector{Point2f0}}
    tickvalues::Node{Vector{Float32}}
    ticklabels::Node{Vector{String}}
end

abstract type LObject end

mutable struct LAxis <: AbstractPlotting.AbstractScene
    parent::Scene
    scene::Scene
    plots::Vector{AxisContent}
    xaxislinks::Vector{LAxis}
    yaxislinks::Vector{LAxis}
    limits::Node{BBox}
    layoutnodes::LayoutNodes
    needs_update::Node{Bool}
    attributes::Attributes
    block_limit_linking::Node{Bool}
    decorations::Dict{Symbol, Any}
end

mutable struct LColorbar <: LObject
    parent::Scene
    scene::Scene
    layoutnodes::LayoutNodes
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

mutable struct LText <: LObject
    parent::Scene
    layoutnodes::LayoutNodes
    text::AbstractPlotting.Text
    attributes::Attributes
end

mutable struct LRect <: LObject
    parent::Scene
    layoutnodes::LayoutNodes
    rect::AbstractPlotting.Poly
    attributes::Attributes
end

struct LSlider <: LObject
    scene::Scene
    layoutnodes::LayoutNodes
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

struct LButton <: LObject
    scene::Scene
    layoutnodes::LayoutNodes
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

struct LToggle <: LObject
    scene::Scene
    layoutnodes::LayoutNodes
    attributes::Attributes
    decorations::Dict{Symbol, Any}
end

abstract type LegendElement end

struct LineElement <: LegendElement
    attributes::Attributes
end

struct MarkerElement <: LegendElement
    attributes::Attributes
end

struct PolyElement <: LegendElement
    attributes::Attributes
end

struct LegendEntry
    elements::Vector{LegendElement}
    attributes::Attributes
end

struct LLegend <: LObject
    scene::Scene
    entries::Node{Vector{LegendEntry}}
    layoutnodes::LayoutNodes
    attributes::Attributes
    decorations::Dict{Symbol, Any}
    entrytexts::Vector{LText}
    entryplots::Vector{Vector{AbstractPlot}}
end

const Indexables = Union{UnitRange, Int, Colon}
