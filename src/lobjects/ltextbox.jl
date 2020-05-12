struct LTextbox <: LObject
    scene::Scene
    attributes::Attributes
    layoutobservables::GridLayoutBase.LayoutObservables
    decorations::Dict{Symbol, Any}
end

function default_attributes(::Type{LTextbox}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        "The height setting of the textbox."
        height = Auto()
        "The width setting of the textbox."
        width = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The horizontal alignment of the textbox in its suggested bounding box."
        halign = :center
        "The vertical alignment of the textbox in its suggested bounding box."
        valign = :center
        "The alignment of the textbox in its suggested bounding box."
        alignmode = Inside()
        "The currently displayed string"
        displayed_string = "Write here"
        "The currently saved string"
        saved_string = "Write here"
        "Text size"
        textsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "Font family"
        font = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "Color of the box"
        boxcolor = :white
        "Color of the box when focused"
        boxcolor_focused = :white
        "Color of the box when hovered"
        boxcolor_hover = :transparent
        "Color of the box border"
        bordercolor = RGBf0(0.95, 0.95, 0.95)
        "Color of the box border when hovered"
        bordercolor_hover = COLOR_ACCENT_DIMMED[]
        "Color of the box border when focused"
        bordercolor_focused = COLOR_ACCENT[]
        "Width of the box border"
        borderwidth = 3f0
        "Padding of the text against the box"
        textpadding = (10, 10, 10, 10)
        "If the textbox is focused and receives text input"
        focused = false
        "Corner radius of text box"
        cornerradius = 15
        "Corner segments of one rounded corner"
        cornersegments = 20

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
        boxcolor, bordercolor, textpadding, bordercolor_focused, bordercolor_hover, focused,
        borderwidth, cornerradius, cornersegments, boxcolor_focused)

    decorations = Dict{Symbol, Any}()

    layoutobservables = LayoutObservables(LTextbox, attrs.width, attrs.height,
        attrs.tellwidth, attrs.tellheight,
        halign, valign, attrs.alignmode; suggestedbbox = bbox)

    scenearea = lift(IRect2D_rounded, layoutobservables.computedbbox)

    scene = Scene(parent, scenearea, raw = true, camera = campixel!)

    bbox = lift(FRect2D ∘ AbstractPlotting.zero_origin, scenearea)

    roundedrectpoints = lift(roundedrectvertices, scenearea, cornerradius, cornersegments)

    box = poly!(parent, roundedrectpoints, strokewidth = borderwidth,
        strokecolor = bordercolor[],
        color = boxcolor, raw = true)[end]


    t = LText(scene, text = displayed_string, bbox = bbox, halign = :left, valign = :top,
        width = Auto(true), height = Auto(true),
        textsize = textsize, padding = textpadding)

    cursorpoints = Node([Point2f0(0, 0), Point2f0(1, 0)])

    on(displayed_string) do s
        # positions, _ = AbstractPlotting.layout_text(s, t.textobject.position[],
        # t.textobject.textsize[],
        # to_font(t.textobject.font[]),
        # to_align(t.textobject.align[]),
        # to_rotation(t.textobject.rotation[]),
        # t.textobject.model[],
        # )
        #
        # p = Point2f0(positions[end])
        #
        # cursorpoints[] = [p .+ Point2f0(10, -5), p .+ Point2f0(10, 25)]
    end

    cursorcolor = Node{Any}(:transparent)
    cursor = linesegments!(scene, cursorpoints, color = cursorcolor, linewidth = 4)[end]

    cursoranim = Animations.Loop(
        Animations.Animation(
            [0, 1.0],
            [Colors.alphacolor(COLOR_ACCENT[], 0), Colors.alphacolor(COLOR_ACCENT[], 1)],
            Animations.sineio(n = 2, yoyo = true, postwait = 0.2)),
            0.0, 0.0, 1000)

    cursoranimtask = nothing

    on(t.layoutobservables.reportedsize) do sz
        layoutobservables.autosize[] = sz
    end

    # trigger text for autosize
    t.text = displayed_string[]

    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    mousestate = addmousestate!(scene)

    function focus()
        if !focused[]
            box.strokecolor = bordercolor_focused[]
            box.color = boxcolor_focused[]
            focused[] = true
            cursoranimtask = Animations.animate_async(cursoranim; fps = 30) do t, color
                cursorcolor[] = color
            end
        end
    end

    function defocus()
        stopanim = false
        box.color = boxcolor[]
        box.strokecolor = bordercolor[]
        if !isnothing(cursoranimtask)
            Animations.stop(cursoranimtask)
            cursoranimtask = nothing
        end
        cursorcolor[] = :transparent
        focused[] = false
    end

    onmouseleftclick(mousestate) do state
        focus()
    end

    onmouseover(mousestate) do state
        if !focused[]
            box.strokecolor = bordercolor_hover[]
        end
    end

    onmouseout(mousestate) do state
        if !focused[]
            box.strokecolor = bordercolor[]
        end
    end

    # onmousedownoutside(mousestate) do state
    #     displayed_string[] = saved_string[]
    #     defocus()
    # end

    on(events(scene).unicode_input) do char_array
        if !focused[] || isempty(char_array)
            return
        end

        displayed_string[] = let
            newstring = join(char_array)
            if iswhitespace(displayed_string[])
                newstring
            else
                displayed_string[] * newstring
            end
        end
    end

    lastset = Set{AbstractPlotting.Keyboard.Button}()
    on(events(scene).keyboardbuttons) do button_set
        if !focused[] || isempty(button_set)
            return
        end

        newkeys = setdiff(button_set, lastset)

        for key in newkeys
            if key == Keyboard.backspace
                displayed_string[] = let
                    c = chop(displayed_string[])
                    # TODO: fix when empty string doesn't error anymore
                    isempty(c) ? " " : c
                end
            elseif key == Keyboard.enter
                saved_string[] = displayed_string[]
                defocus()
            elseif key == Keyboard.escape
                displayed_string[] = saved_string[]
                defocus()
            end
        end

        # lastset = button_set
    end

    LTextbox(scene, attrs, layoutobservables, decorations)
end
