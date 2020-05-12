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
        boxcolor = :transparent
        "Color of the box when focused"
        boxcolor_focused = :transparent
        "Color of the box when focused"
        boxcolor_focused_invalid = RGBAf0(1, 0, 0, 0.3)
        "Color of the box when hovered"
        boxcolor_hover = :transparent
        "Color of the box border"
        bordercolor = RGBf0(0.95, 0.95, 0.95)
        "Color of the box border when hovered"
        bordercolor_hover = COLOR_ACCENT_DIMMED[]
        "Color of the box border when focused"
        bordercolor_focused = COLOR_ACCENT[]
        "Color of the box border when focused and invalid"
        bordercolor_focused_invalid = RGBf0(1, 0, 0)
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
        "Function taking a string and returning a boolean which decides if the input is valid."
        validator = str -> true

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
        boxcolor, boxcolor_focused_invalid, boxcolor_focused, boxcolor_hover,
        bordercolor, textpadding, bordercolor_focused, bordercolor_hover, focused,
        bordercolor_focused_invalid,
        borderwidth, cornerradius, cornersegments, boxcolor_focused, validator)

    decorations = Dict{Symbol, Any}()

    layoutobservables = LayoutObservables(LTextbox, attrs.width, attrs.height,
        attrs.tellwidth, attrs.tellheight,
        halign, valign, attrs.alignmode; suggestedbbox = bbox)

    scenearea = lift(IRect2D_rounded, layoutobservables.computedbbox)

    scene = Scene(parent, scenearea, raw = true, camera = campixel!)

    bbox = lift(FRect2D ∘ AbstractPlotting.zero_origin, scenearea)

    roundedrectpoints = lift(roundedrectvertices, scenearea, cornerradius, cornersegments)

    content_is_valid = lift(displayed_string, validator) do str, validator
        valid::Bool = validate_textbox(str, validator)
    end

    hovering = Node(false)

    realbordercolor = lift(bordercolor, bordercolor_focused,
        bordercolor_focused_invalid, bordercolor_hover, focused, content_is_valid, hovering,
        typ = Any) do bc, bcf, bcfi, bch, focused, valid, hovering

        if focused
            valid ? bcf : bcfi
        else
            hovering ? bch : bc
        end
    end

    realboxcolor = lift(boxcolor, boxcolor_focused,
        boxcolor_focused_invalid, boxcolor_hover, focused, content_is_valid, hovering,
        typ = Any) do bc, bcf, bcfi, bch, focused, valid, hovering

        if focused
            valid ? bcf : bcfi
        else
            hovering ? bch : bc
        end
    end

    box = poly!(parent, roundedrectpoints, strokewidth = borderwidth,
        strokecolor = realbordercolor,
        color = realboxcolor, raw = true)[end]

    displayed_chars = @lift([c for c in $displayed_string])

    t = LText(scene, text = displayed_string, bbox = bbox, halign = :left, valign = :top,
        width = Auto(true), height = Auto(true),
        textsize = textsize, padding = textpadding)

    displayed_charbbs = lift(t.layoutobservables.reportedsize) do sz
        charbbs(t.textobject)
    end


    cursorindex = Node(length(displayed_string[]))

    cursorpoints = lift(cursorindex, displayed_charbbs) do ci, bbs
        if ci == 0
            [leftline(bbs[1])...]
        else
            [rightline(bbs[ci])...]
        end
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
            focused[] = true
            cursoranimtask = Animations.animate_async(cursoranim; fps = 30) do t, color
                cursorcolor[] = color
            end
        end
    end

    function defocus()
        if !isnothing(cursoranimtask)
            Animations.stop(cursoranimtask)
            cursoranimtask = nothing
        end
        cursorcolor[] = :transparent
        focused[] = false
    end

    onmouseleftclick(mousestate) do state
        focus()
        pos = state.pos
        closest_charindex = argmin(
            [sum((pos .- center(bb)).^2) for bb in displayed_charbbs[]]
        )
        # set cursor to index of closest char if right of center, or previous char if left of center
        cursorindex[] = if (pos .- center(displayed_charbbs[][closest_charindex]))[1] > 0
            closest_charindex
        else
            closest_charindex - 1
        end
    end

    onmouseover(mousestate) do state
        hovering[] = true
    end

    onmouseout(mousestate) do state
        hovering[] = false
    end

    onmousedownoutside(mousestate) do state
        displayed_string[] = saved_string[]
        defocus()
    end

    function insertchar!(c, index)
        if displayed_chars[] == [' ']
            empty!(displayed_chars[])
            index = 1
        end
        newchars = [displayed_chars[][1:index-1]; c; displayed_chars[][index:end]]
        displayed_string[] = join(newchars)
        cursorindex[] = index
    end

    function appendchar!(c)
        insertchar!(c, length(displayed_string[]))
    end

    function removechar!(index)
        newchars = [displayed_chars[][1:index-1]; displayed_chars[][index+1:end]]

        if isempty(newchars)
            newchars = [' ']
        end

        if cursorindex[] >= index
            cursorindex[] = max(1, cursorindex[] - 1)
        end

        displayed_string[] = join(newchars)
    end

    on(events(scene).unicode_input) do char_array
        if !focused[] || isempty(char_array)
            return
        end

        for c in char_array
            insertchar!(c, cursorindex[] + 1)
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
                removechar!(cursorindex[])
            elseif key == Keyboard.enter
                saved_string[] = displayed_string[]
                defocus()
            elseif key == Keyboard.escape
                displayed_string[] = saved_string[]
                defocus()
            elseif key == Keyboard.right
                cursorindex[] = min(length(displayed_string[]), cursorindex[] + 1)
            elseif key == Keyboard.left
                cursorindex[] = max(0, cursorindex[] - 1)
            end
        end

        # lastset = button_set
    end

    LTextbox(scene, attrs, layoutobservables, decorations)
end


function charbbs(text)
    positions = AbstractPlotting.layout_text(text[1][], text.position[], text.textsize[],
        text.font[], text.align[], text.rotation[], text.model[],
        text.justification[], text.lineheight[])

    font = AbstractPlotting.to_font(text.font[])

    bbs = [
        AbstractPlotting.FreeTypeAbstraction.height_insensitive_boundingbox(
            AbstractPlotting.FreeTypeAbstraction.get_extent(font, char),
            font
        )
        for char in text[1][]
    ]

    bbs_shifted_scaled = [Rect2D(
            (AbstractPlotting.origin(bb) .* text.textsize[] .+ pos[1:2])...,
            (widths(bb) .* text.textsize[])...)
        for (bb, pos) in zip(bbs, positions)]
end

function validate_textbox(str, validator::Function)
    validator(str)
end

function validate_textbox(str, validator::Regex)
    m = match(validator, str)
    # check that the validator matches the whole string
    !isnothing(m) && m.match == str
end