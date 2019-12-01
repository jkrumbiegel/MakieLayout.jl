# # Default attributes for layouted objects
# Here, we are essentially implementing the expansion done by the `@recipe` macro.

function default_attributes(::Type{LayoutedAxis})
    Attributes(
        xlabel = "x label",
        ylabel = "y label",
        title = "Title",
        titlefont = "DejaVu Sans",
        titlesize = 30f0,
        titlegap = 10f0,
        titlevisible = true,
        titlealign = :center,
        xlabelcolor = RGBf0(0, 0, 0),
        ylabelcolor = RGBf0(0, 0, 0),
        xlabelsize = 20f0,
        ylabelsize = 20f0,
        xlabelvisible = true,
        ylabelvisible = true,
        xlabelpadding = 5f0,
        ylabelpadding = 5f0,
        xticklabelsize = 20f0,
        yticklabelsize = 20f0,
        xticklabelsvisible = true,
        yticklabelsvisible = true,
        xticklabelspace = 20f0,
        yticklabelspace = 50f0,
        xticklabelpad = 5f0,
        yticklabelpad = 5f0,
        xticklabelrotation = 0f0,
        yticklabelrotation = 0f0,
        xticklabelalign = (:center, :top),
        yticklabelalign = (:right, :center),
        xticksize = 10f0,
        yticksize = 10f0,
        xticksvisible = true,
        yticksvisible = true,
        xtickalign = 0f0,
        ytickalign = 0f0,
        xtickwidth = 1f0,
        ytickwidth = 1f0,
        xtickcolor = RGBf0(0, 0, 0),
        ytickcolor = RGBf0(0, 0, 0),
        xpanlock = false,
        ypanlock = false,
        xzoomlock = false,
        yzoomlock = false,
        spinewidth = 1f0,
        xgridvisible = true,
        ygridvisible = true,
        xgridwidth = 1f0,
        ygridwidth = 1f0,
        xgridcolor = RGBAf0(0, 0, 0, 0.1),
        ygridcolor = RGBAf0(0, 0, 0, 0.1),
        topspinevisible = true,
        rightspinevisible = true,
        leftspinevisible = true,
        bottomspinevisible = true,
        topspinecolor = RGBf0(0, 0, 0),
        leftspinecolor = RGBf0(0, 0, 0),
        rightspinecolor = RGBf0(0, 0, 0),
        bottomspinecolor = RGBf0(0, 0, 0),
        aspect = nothing,
        alignment = (0.5f0, 0.5f0),
        maxsize = (Inf32, Inf32),
        xautolimitmargin = (0.05f0, 0.05f0),
        yautolimitmargin = (0.05f0, 0.05f0),
        xticks = AutoLinearTicks(100f0),
        yticks = AutoLinearTicks(100f0),
        panbutton = AbstractPlotting.Mouse.right,
        xpankey = AbstractPlotting.Keyboard.x,
        ypankey = AbstractPlotting.Keyboard.y,
        xzoomkey = AbstractPlotting.Keyboard.x,
        yzoomkey = AbstractPlotting.Keyboard.y,
        xaxisposition = :bottom,
        yaxisposition = :left,
        xoppositespinevisible = true,
        yoppositespinevisible = true,
    )
end

# Nested Axis theme structure:

axis_attrs = (
    alignment = 0.5f0,
    maxsize = Inf32,
    # axis labels
    label = (
        text    = "x label",
        visible = true,
        font    = "DejaVu Sans",
        color   = RGBf0(0, 0, 0),
        size    = 20f0,
        padding = 5f0
    ),

    # tick marks and labels
    ticks = (
        # tick marks
        ticks   = AutoLinearTicks(100f0),
        autolimitmargin = 0.05f0,
        size    = 10f0,
        visible = true,
        color   = RGBf0(0, 0, 0),
        align   = 0f0,
        width   = 1f0,
        style   = nothing,

        # tick labels
        label = (
            size      = 20f0,
            formatter = Formatting.format,
            visible   = true,
            font      = "DejaVu Sans",
            color     = RGBf0(0, 0, 0),
            spacing   = 20f0, 50f0,
            padding   = 5f0,
            rotation  = 0f0,
            align     = (:center, :top)
        ),
    ),

    # grid of minor tick lines
    grid = (
        visible = true,
        color   = RGBf0(0, 0, 0),
        width   = 1f0,
        style   = nothing
    ),

    pan = (
        lock = false,
        key = Keyboard.x
    ),
    zoom = (
        lock = false,
        key = Keyboard.x
    )
)

yaxis_diff = (
    ticks = (
        label = (
            text    = "y label",
            spacing = 50f0,
            align = (:right, :center),
        ),
    ),
    pan = (
        key = Keyboard.y
    ),
    zoom = (
        key = Keyboard.y
    )

)

xaxis_attrs = axis_attrs
yaxis_attrs = merge(axis_attrs, yaxis_diff)

# Frames
frame = (visible = true, color = RGBAf0(0, 0, 0), size = 1f0, style = nothing)


# For the layouted axis:


Attributes(
    # Top-level attributes
    aspect = nothing,
    panbutton = Mouse.right,

    # Nested attributes
    title = (
        text     = "Title",
        visible  = true,
        font     = "DejaVu Sans",
        color    = RGBf0(0, 0, 0),
        size     = 30f0,
        gap      = 10f0,
        align    = :center,
    ),

    # Side label
    sidelabel = (
        text     = "Side Label",
        size     = 30f0,
        gap      = 10f0,
        visible  = false,
        align    = :center,
        font     = "Dejavu Sans",
        rotation = -pi/2
    ),

    # frames
    frames = (
        top    = frame,
        bottom = frame,
        left   = frame,
        right  = frame,
    ),

    # Per-axis attributes
    x = xaxis_attrs,
    y = yaxis_attrs
)

function default_attributes(::Type{LayoutedColorbar})
    Attributes(
        label = "label",
        labelcolor = RGBf0(0, 0, 0),
        labelsize = 20f0,
        labelvisible = true,
        labelpadding = 5f0,
        ticklabelsize = 20f0,
        ticklabelsvisible = true,
        ticksize = 10f0,
        ticksvisible = true,
        ticklabelspace = 30f0,
        ticklabelpad = 5f0,
        tickalign = 0f0,
        tickwidth = 1f0,
        tickcolor = RGBf0(0, 0, 0),
        ticklabelalign = (:left, :center),
        spinewidth = 1f0,
        idealtickdistance = 100f0,
        topspinevisible = true,
        rightspinevisible = true,
        leftspinevisible = true,
        bottomspinevisible = true,
        topspinecolor = RGBf0(0, 0, 0),
        leftspinecolor = RGBf0(0, 0, 0),
        rightspinecolor = RGBf0(0, 0, 0),
        bottomspinecolor = RGBf0(0, 0, 0),
        alignment = (:center, :center),
        vertical = true,
        flipaxisposition = true,
        width = nothing,
        height = nothing,
        colormap = :viridis,
    )
end

function default_attributes(::Type{LayoutedText})
    Attributes(
        text = "Text",
        visible = true,
        color = RGBf0(0, 0, 0),
        textsize = 20f0,
        font = "Dejavu Sans",
        valign = :center,
        halign = :center,
        rotation = 0f0,
        padding = (0f0, 0f0, 0f0, 0f0),
    )
end

function default_attributes(::Type{LayoutedRect})
    Attributes(
        visible = true,
        color = RGBf0(0.9, 0.9, 0.9),
        valign = :center,
        halign = :center,
        padding = (0f0, 0f0, 0f0, 0f0),
        strokewidth = 2f0,
        strokevisible = true,
        strokecolor = RGBf0(0, 0, 0),
    )
end

function default_attributes(::Type{LayoutedButton})
    Attributes(
        valign = :center,
        halign = :center,
        padding = (0f0, 0f0, 0f0, 0f0),
        textsize = 20f0,
        label = "Button",
    )
end

function default_attributes(::Type{AxisContent})
    Attributes(
        xautolimit = true,
        yautolimit = true,
    )
end

function default_attributes(::Type{LineAxis})
    Attributes(
        endpoints = (Point2f0(0, 0), Point2f0(100, 0)),
        limits = (0f0, 100f0),
        flipped = false,
        ticksize = 10f0,
        tickwidth = 1f0,
        tickcolor = RGBf0(0, 0, 0),
        tickalign = 0f0,
        ticks = AutoLinearTicks(100f0),
        ticklabelalign = (:center, :top),
        ticksvisible = true,
        ticklabelrotation = 0f0,
        ticklabelsize = 20f0,
        ticklabelsvisible = true,
        spinewidth = 1f0,
        label = "label",
        labelsize = 20f0,
        labelcolor = RGBf0(0, 0, 0),
        labelvisible = true,
        ticklabelspace = 30f0,
        ticklabelpad = 5f0,
        labelpadding = 10f0,
    )
end
