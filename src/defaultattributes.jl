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
        sidelabel = "Side Label",
        sidelabelsize = 30f0,
        sidelabelgap = 10f0,
        sidelabelvisible = false,
        sidelabelalign = :center,
        sidelabelfont = "Dejavu Sans",
        sidelabelrotation = -pi/2,
    )
end

# Nested Axis theme structure:

Attributes(
    # Top-level attributes
    aspect = nothing,
    alignment = (0.5f0, 0.5f0),
    maxsize = (Inf32, Inf32),

    # Nested attributes
    title = (
        text    = "Title",
        visible = true,
        font    = "DejaVu Sans",
        color   = RGBf0(0, 0, 0),
        size    = 30f0,
        gap     = 10f0,
        align   = :center,
    ),

    # Side label
    sidelabel = (
        text = "Side Label",
        size = 30f0,
        gap = 10f0,
        visible = false,
        align = :center,
        font = "Dejavu Sans",
        rotation = -pi/2
    ),

    # axis labels
    labels = (
        text    = ("x label", "y label"),
        visible = (true, true),
        font    = ("DejaVu Sans", "DejaVu Sans"),
        color   = (RGBf0(0, 0, 0), RGBf0(0, 0, 0)),
        size    = (20f0, 20f0),
        padding = (5f0, 5f0)
    ),

    # tick marks and labels
    ticks = (
        # tick marks
        ticks   = (AutoLinearTicks(100f0), AutoLinearTicks(100f0)),
        autolimitmargin = (0.05ff0, 0.05f0),
        size    = (10f0, 10f0),
        visible = (true, true),
        color   = (RGBf0(0, 0, 0), RGBf0(0, 0, 0)),
        align   = (0f0, 0f0),
        width   = (1f0, 1f0),

        # tick labels
        labels = (
            size     = (20f0, 20f0),
            formatter = (Formatters.format, Formatters.format)
            visible  = (true, true),
            color    = (RGBf0(0, 0, 0), RGBf0(0, 0, 0)),
            spacing  = (20f0, 50f0),
            padding  = (5f0, 5f0),
            rotation = (0f0, 0f0),
            align    = ((:center, :top), (:right, :center)),
        ),
    ),

    # grid of minor tick lines
    grid = (
        visible = (true, true),
        color   = (RGBf0(0, 0, 0), RGBf0(0, 0, 0)),
        width   = (1f0, 1f0),
        style   = (nothing, nothing)
    ),

    # frame
    frame = ( # top,right, bottom, left?
        visible = (true, true, true, true)
        color   = (RGBf0(0, 0, 0), RGBf0(0, 0, 0), RGBf0(0, 0, 0), RGBf0(0, 0, 0)).
        size    = (1f0, 1f0, 1f0, 1f0),
        style   = (nothing, nothing, nothing, nothing)
    ),

    actions = (
        pan = (
            lock = (false, false),
            key  = (Button.x, Button.y),
            button = Mouse.right
        ),
        zoom = (
            lock = (false, false),
            key  = (Button.x, Button.y)
        ),
    ),
)

function default_attributes(::Type{LayoutedColorbar})
    Attributes(
        label = "label",
        title = "Title",
        titlefont = "DejaVu Sans",
        titlesize = 30f0,
        titlegap = 10f0,
        titlevisible = true,
        titlealign = :center,
        labelcolor = RGBf0(0, 0, 0),
        labelsize = 20f0,
        labelvisible = true,
        labelpadding = 5f0,
        ticklabelsize = 20f0,
        ticklabelsvisible = true,
        ticksize = 10f0,
        ticksvisible = true,
        ticklabelpad = 20f0,
        tickalign = 0f0,
        tickwidth = 1f0,
        tickcolor = RGBf0(0, 0, 0),
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
        aspect = nothing,
        alignment = (0.5f0, 0.5f0),
        maxsize = (Inf32, Inf32),
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
