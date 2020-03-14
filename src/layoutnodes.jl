function LayoutNodes(T::Type, width::Node, height::Node, halign::Node, valign::Node;
        suggestedbbox = nothing,
        protrusions = nothing,
        computedsize = nothing,
        autosize = nothing,
        computedbbox = nothing,
        gridcontent = nothing)

    sizenode = sizenode!(width, height)
    alignment = lift(tuple, halign, valign)

    suggestedbbox_node = create_suggested_bboxnode(suggestedbbox)
    protrusions = create_protrusions(protrusions)
    autosizenode = Node{NTuple{2, Optional{Float32}}}((nothing, nothing))
    computedsize = computedsizenode!(sizenode, autosizenode)
    finalbbox = alignedbboxnode!(suggestedbbox_node, computedsize, alignment, sizenode, autosizenode)

    LayoutNodes{T, GridLayout}(suggestedbbox_node, protrusions, computedsize, autosizenode, finalbbox, nothing)
end


create_suggested_bboxnode(n::Nothing) = Node(BBox(0, 100, 0, 100))
create_suggested_bboxnode(tup::Tuple) = Node(BBox(tup...))
create_suggested_bboxnode(bbox::AbstractPlotting.Rect2D) = Node(BBox(bbox))
create_suggested_bboxnode(node::Node{BBox}) = node

create_protrusions(p::Nothing) = Node(RectSides{Float32}(0, 0, 0, 0))
create_protrusions(p::Node{RectSides{Float32}}) = p
create_protrusions(p::RectSides{Float32}) = Node(p)


function sizenode!(widthattr::Node, heightattr::Node)
    sizeattrs = Node{Tuple{Any, Any}}((widthattr[], heightattr[]))
    onany(widthattr, heightattr) do w, h
        sizeattrs[] = (w, h)
    end
    sizeattrs
end

function computedsizenode!(sizeattrs, autosizenode::Node{NTuple{2, Optional{Float32}}})

    # set up csizenode with correct type manually
    csizenode = Node{NTuple{2, Optional{Float32}}}((nothing, nothing))

    onany(sizeattrs, autosizenode) do sizeattrs, autosize

        wattr, hattr = sizeattrs
        wauto, hauto = autosize

        wsize = computed_size(wattr, wauto)
        hsize = computed_size(hattr, hauto)

        csizenode[] = (wsize, hsize)
    end

    # trigger first value
    sizeattrs[] = sizeattrs[]

    csizenode
end

function computed_size(sizeattr, autosize)
    ms = @match sizeattr begin
        sa::Nothing => nothing
        sa::Real => sa
        sa::Fixed => sa.x
        sa::Relative => nothing
        sa::Auto => if sa.trydetermine
                # if trydetermine we report the autosize to the layout
                autosize
            else
                # but not if it's false, this allows for single span content
                # not to shrink its column or row, like a small legend next to an
                # axis or a super title over a single axis
                nothing
            end
        sa => error("""
            Invalid size attribute $sizeattr.
            Can only be Nothing, Fixed, Relative, Auto or Real""")
    end
end


function alignedbboxnode!(
    suggestedbbox::Node{BBox},
    computedsize::Node{NTuple{2, Optional{Float32}}},
    alignment::Node,
    sizeattrs::Node,
    autosizenode::Node{NTuple{2, Optional{Float32}}})

    finalbbox = Node(BBox(0, 100, 0, 100))

    onany(suggestedbbox, alignment, computedsize) do sbbox, al, csize

        bw = width(sbbox)
        bh = height(sbbox)

        # we only passively retrieve sizeattrs here because if they change
        # they also trigger computedsize, which triggers this node, too
        # we only need to know here if there are relative sizes given, because
        # those can only be computed knowing the suggestedbbox
        widthattr, heightattr = sizeattrs[]

        cwidth, cheight = csize

        w = if isnothing(cwidth)
            @match widthattr begin
                wa::Relative => wa.x * bw
                wa::Nothing => bw
                wa::Auto => if isnothing(autosizenode[][1])
                        # we have no autowidth available anyway
                        # take suggested width
                        bw
                    else
                        # use the width that was auto-computed
                        autosizenode[][1]
                    end
                wa => error("At this point, if computed width is not known,
                widthattr should be a Relative or Nothing, not $wa.")
            end
        else
            cwidth
        end

        h = if isnothing(cheight)
            @match heightattr begin
                ha::Relative => ha.x * bh
                ha::Nothing => bh
                ha::Auto => if isnothing(autosizenode[][2])
                        # we have no autoheight available anyway
                        # take suggested height
                        bh
                    else
                        # use the height that was auto-computed
                        autosizenode[][2]
                    end
                ha => error("At this point, if computed height is not known,
                heightattr should be a Relative or Nothing, not $ha.")
            end
        else
            cheight
        end

        # how much space is left in the bounding box
        rw = bw - w
        rh = bh - h

        xshift = @match al[1] begin
            :left => 0.0f0
            :center => 0.5f0 * rw
            :right => rw
            x::Real => x * rw
            x => error("Invalid horizontal alignment $x (only Real or :left, :center, or :right allowed).")
        end

        yshift = @match al[2] begin
            :bottom => 0.0f0
            :center => 0.5f0 * rh
            :top => rh
            x::Real => x * rh
            x => error("Invalid vertical alignment $x (only Real or :bottom, :center, or :top allowed).")
        end

        # align the final bounding box in the layout bounding box
        l = left(sbbox) + xshift
        b = bottom(sbbox) + yshift
        r = l + w
        t = b + h

        newbbox = BBox(l, r, b, t)
        # if finalbbox[] != newbbox
        #     finalbbox[] = newbbox
        # end
        finalbbox[] = newbbox
    end

    finalbbox
end

"""
    layoutnodes(x::T) where T

Access `x`'s field `:layoutnodes` containing a `LayoutNodes` instance. This should
be overloaded for any type that is layoutable but stores its `LayoutNodes` in
a differently named field.
"""
function layoutnodes(x::T) where T
    if hasfield(T, :layoutnodes) && fieldtype(T, :layoutnodes) <: LayoutNodes
        x.layoutnodes
    else
        error("It's not defined how to get LayoutNodes for type $T, overload this method for layoutable types.")
    end
end

# These are the default API functions to retrieve the layout parts from an object
protrusionnode(x) = layoutnodes(x).protrusions
suggestedbboxnode(x) = layoutnodes(x).suggestedbbox
computedsizenode(x) = layoutnodes(x).computedsize
autosizenode(x) = layoutnodes(x).autosize
computedbboxnode(x) = layoutnodes(x).computedbbox
gridcontent(x) = layoutnodes(x).gridcontent
