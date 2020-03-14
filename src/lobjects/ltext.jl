function LText(parent::Scene, text; kwargs...)
    LText(parent; text = text, kwargs...)
end

function LText(parent::Scene; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LText))

    @extract attrs (text, textsize, font, color, visible, halign, valign,
        rotation, padding)

    layoutnodes = LayoutNodes(LText, attrs.width, attrs.height, halign, valign; suggestedbbox = bbox)

    textpos = Node(Point3f0(0, 0, 0))

    t = text!(parent, text, position = textpos, textsize = textsize, font = font, color = color,
        visible = visible, align = (:center, :center), rotation = rotation, raw = true)[end]

    ltext = LText(parent, layoutnodes, t, attrs)

    textbb = BBox(0, 1, 0, 1)

    onany(text, textsize, font, rotation, padding) do text, textsize, font, rotation, padding
        textbb = FRect2D(boundingbox(t))
        autowidth = width(textbb) + padding[1] + padding[2]
        autoheight = height(textbb) + padding[3] + padding[4]
        autosizenode(ltext)[] = (autowidth, autoheight)
    end

    onany(computedbboxnode(ltext), padding) do bbox, padding

        tw = width(textbb)
        th = height(textbb)

        box = bbox.origin[1]
        boy = bbox.origin[2]

        tx = box + padding[1] + 0.5 * tw
        ty = boy + padding[3] + 0.5 * th

        textpos[] = Point3f0(tx, ty, 0)
    end

    # trigger first update, otherwise bounds are wrong somehow
    text[] = text[]
    # trigger bbox
    suggestedbboxnode(ltext)[] = suggestedbboxnode(ltext)[]

    ltext
end

defaultlayout(lt::LText) = ProtrusionLayout(lt)


function Base.getproperty(lt::LText, s::Symbol)
    if s in fieldnames(LText)
        getfield(lt, s)
    else
        lt.attributes[s]
    end
end

function Base.setproperty!(lt::LText, s::Symbol, value)
    if s in fieldnames(LText)
        setfield!(lt, s, value)
    else
        lt.attributes[s][] = value
    end
end

function Base.propertynames(lt::LText)
    [fieldnames(LText)..., keys(lt.attributes)...]
end

function Base.delete!(lt::LText)

    disconnect_layoutnodes!(lt.layoutnodes.gridcontent)
    remove_from_gridlayout!(lt.layoutnodes.gridcontent)
    empty!(lt.layoutnodes.suggestedbbox.listeners)
    empty!(lt.layoutnodes.computedbbox.listeners)
    empty!(lt.layoutnodes.computedsize.listeners)
    empty!(lt.layoutnodes.autosize.listeners)
    empty!(lt.layoutnodes.protrusions.listeners)

    # remove the plot object from the scene
    delete!(lt.parent, lt.textobject)
end
