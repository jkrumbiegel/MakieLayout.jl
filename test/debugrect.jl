mutable struct DebugRect <: MakieLayout.LObject
    layoutnodes::MakieLayout.LayoutNodes
    attributes::Attributes
end

function default_attributes(T::Type{DebugRect})
    Attributes(
        height = nothing,
        width = nothing,
        halign = :center,
        valign = :center,
        topprot = 0,
        leftprot = 0,
        rightprot = 0,
        bottomprot = 0
    )
end

function DebugRect(; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(DebugRect))

    @extract attrs (valign, halign, topprot, leftprot, rightprot, bottomprot)

    sizeattrs = MakieLayout.sizenode!(attrs.width, attrs.height)
    alignment = lift(tuple, halign, valign)

    suggestedbbox = MakieLayout.create_suggested_bboxnode(bbox)

    autosizenode = Node{NTuple{2, MakieLayout.Optional{Float32}}}((nothing, nothing))

    computedsize = MakieLayout.computedsizenode!(sizeattrs, autosizenode)

    finalbbox = MakieLayout.alignedbboxnode!(suggestedbbox, computedsize, alignment, sizeattrs, autosizenode)

    # no protrusions
    protrusions = lift(leftprot, rightprot, bottomprot, topprot) do l, r, b, t
        MakieLayout.RectSides{Float32}(l, r, b, t)
    end

    layoutnodes = MakieLayout.LayoutNodes{DebugRect, GridLayout}(suggestedbbox, protrusions, computedsize, autosizenode, finalbbox, nothing)

    # trigger bbox
    suggestedbbox[] = suggestedbbox[]

    DebugRect(layoutnodes, attrs)
end
