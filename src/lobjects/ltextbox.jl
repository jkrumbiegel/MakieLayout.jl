struct LTextbox <: LObject
    scene::Scene
    attributes::Attributes
    layoutobservables::GridLayoutBase.LayoutObservables
    decorations::Dict{Symbol, Any}
end

function default_attributes(::Type{LTextbox}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        "The height setting of the textbox."
        height = Auto(true)
        "The width setting of the textbox."
        width = Auto(true)
        "The horizontal alignment of the textbox in its suggested bounding box."
        halign = :center
        "The vertical alignment of the textbox in its suggested bounding box."
        valign = :center
        "The alignment of the textbox in its suggested bounding box."
        alignmode = Inside()
        "The currently displayed string"
        displayed_string = "Textbox"
        "The currently saved string"
        saved_string = ""
        "Text size"
        textsize = 30f0
        "Color of the box"
        boxcolor = :transparent
        "Color of the box border"
        bordercolor = :black
        "Color of the box border when focused"
        bordercolor_focused = :blue
        "Width of the box border"
        borderwidth = 3f0,
        "Padding of the text against the box"
        textpadding = (10, 10, 10, 10)
        "If the textbox is focused and receives text input"
        focused = false

    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
    LTextbox(parent::Scene; bbox = nothing, kwargs...)

LTextbox has the following attributes:

$(let
    _, docs, defaults = default_attributes(LTextbox, nothing)
    docvarstring(docs, defaults)
end)
"""
LTextbox


function LTextbox(parent::Scene; bbox = nothing, kwargs...)

    attrs = merge!(
        Attributes(kwargs),
        default_attributes(LTextbox, parent).attributes)

    @extract attrs (halign, valign, textsize, displayed_string, saved_string,
        boxcolor, bordercolor, textpadding, bordercolor_focused, focused,
        borderwidth)

    decorations = Dict{Symbol, Any}()

    layoutobservables = LayoutObservables(LTextbox, attrs.width, attrs.height,
    halign, valign, attrs.alignmode; suggestedbbox = bbox)

    scenearea = lift(IRect2D_rounded, layoutobservables.computedbbox)

    scene = Scene(parent, scenearea, raw = true, camera = campixel!)

    bbox = lift(FRect2D ∘ AbstractPlotting.zero_origin, scenearea)

    box = LRect(scene, bbox = bbox, linewidth = borderwidth,
        color = boxcolor, strokecolor = @lift($focused ? $bordercolor_focused : $bordercolor),
        width = nothing, height = nothing)

    t = LText(scene, text = displayed_string, bbox = bbox, halign = :left, valign = :top,
        width = Auto(true), height = Auto(true),
        textsize = textsize, padding = textpadding)

    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    on(t.layoutobservables.computedsize) do sz
        @show sz
        layoutobservables.autosize[] = sz
    end

    mousestate = addmousestate!(scene)

    onmouseleftclick(mousestate) do state
        focused[] = true
    end

    onmousedownoutside(mousestate) do state
        focused[] = false
    end

    on(events(scene).keyboardbuttons) do but
        if !focused[] || length(but) != 1
            return
        end

        KB = AbstractPlotting.Keyboard

        b = first(but)

        if b == KB.backspace
            displayed_string[] = chop(displayed_string[])
        else
            for char in 'a':'z'
                if b == getfield(KB, Symbol(char))
                    displayed_string[] = displayed_string[] * char
                    return
                end
            end
        end
    end

    LTextbox(scene, attrs, layoutobservables, decorations)
end
