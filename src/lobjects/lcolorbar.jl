function LColorbar(parent::Scene, plot::AbstractPlot; kwargs...)

    LColorbar(parent;
        colormap = plot.colormap,
        limits = plot.colorrange,
        kwargs...
    )

end

function LColorbar(parent::Scene, heatmap::Heatmap; kwargs...)

    LColorbar(parent;
        colormap = heatmap.colormap,
        limits = heatmap.colorrange,
        highclip = heatmap.highclip,
        lowclip = heatmap.lowclip,
        kwargs...
    )

end

function LColorbar(parent::Scene; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LColorbar, parent).attributes)

    default_attrs = default_attributes(LColorbar, parent).attributes
    theme_attrs = subtheme(parent, :LColorbar)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    @extract attrs (
        label, labelcolor, labelsize, labelvisible, labelpadding, ticklabelsize,
        ticklabelspace, labelfont, ticklabelfont,
        ticklabelsvisible, ticks, tickformat, ticksize, ticksvisible, ticklabelpad, tickalign,
        tickwidth, tickcolor, spinewidth, topspinevisible,
        rightspinevisible, leftspinevisible, bottomspinevisible, topspinecolor,
        leftspinecolor, rightspinecolor, bottomspinecolor, colormap, limits,
        halign, valign, vertical, flipaxisposition, ticklabelalign, flip_vertical_label,
        nsteps, highclip, lowclip)

    decorations = Dict{Symbol, Any}()

    protrusions = Node(GridLayoutBase.RectSides{Float32}(0, 0, 0, 0))
    layoutobservables = LayoutObservables(LColorbar, attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
        halign, valign, attrs.alignmode; suggestedbbox = bbox, protrusions = protrusions)

    framebox = layoutobservables.computedbbox

    highclip_tri_visible = lift(x -> !(isnothing(x) || to_color(x) == to_color(:transparent)), highclip)
    lowclip_tri_visible = lift(x -> !(isnothing(x) || to_color(x) == to_color(:transparent)), lowclip)

    tri_heights = lift(highclip_tri_visible, lowclip_tri_visible, framebox) do hv, lv, box
        if vertical[]
            (lv * width(box), hv * width(box))
        else
            (lv * height(box), hv * height(box))
        end .* sin(pi/3)
    end

    barsize = lift(tri_heights) do heights
        if vertical[]
            max(1, height(framebox[]) - sum(heights))
        else
            max(1, width(framebox[]) - sum(heights))
        end
    end

    barbox = lift(barsize) do sz
        fbox = framebox[]
        if vertical[]
            BBox(left(fbox), right(fbox), bottom(fbox) + tri_heights[][1], top(fbox) - tri_heights[][2])
        else
            BBox(left(fbox) + tri_heights[][1], right(fbox) - tri_heights[][2], bottom(fbox), top(fbox))
        end
    end

    xrange = lift(barbox) do fb
        range(left(fb), right(fb), length = 2)
    end
    yrange = lift(barbox) do fb
        range(bottom(fb), top(fb), length = 2)
    end

    colorcells = lift(vertical, nsteps) do v, nsteps
        if v
            reshape(collect(1:nsteps), 1, :)
        else
            reshape(collect(1:nsteps), :, 1)
        end
    end

    hm = heatmap!(parent, xrange, yrange, colorcells, colormap = colormap, raw = true)[end]
    decorations[:heatmap] = hm

    ab, al, ar, at = axislines!(
        parent, barbox, spinewidth, topspinevisible, rightspinevisible,
        leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
        rightspinecolor, bottomspinecolor)
    decorations[:topspine] = at
    decorations[:leftspine] = al
    decorations[:rightspine] = ar
    decorations[:bottomspine] = ab


    highclip_tri = lift(barbox, spinewidth) do box, spinewidth
        # if vertical[]
            lb, rb = topline(box)
            l = lb .+ (-spinewidth/2, spinewidth/2)
            r = rb .+ (spinewidth/2, spinewidth/2)
            t = ((l .+ r) ./ 2) .+ Point2f0(0, sqrt(sum((r .- l) .^ 2)) * sin(pi/3))
            [l, r, t]
        # end
    end

    highclip_tri_color = Observables.map(highclip) do hc
        to_color(isnothing(hc) ? :transparent : hc)
    end

    highclip_tri = poly!(parent, highclip_tri, color = highclip_tri_color,
        strokecolor = :black,
        strokewidth = spinewidth,
        visible = lift(x -> !(isnothing(x) || to_color(x) == to_color(:transparent)), highclip))[end]
    decorations[:highclip] = highclip_tri


    lowclip_tri = lift(barbox, spinewidth) do box, spinewidth
        # if vertical[]
            lb, rb = bottomline(box)
            l = lb .+ (-spinewidth/2, spinewidth/2)
            r = rb .+ (spinewidth/2, spinewidth/2)
            t = ((l .+ r) ./ 2) .- Point2f0(0, sqrt(sum((r .- l) .^ 2)) * sin(pi/3))
            [l, r, t]
        # end
    end

    lowclip_tri_color = Observables.map(lowclip) do lc
        to_color(isnothing(lc) ? :transparent : lc)
    end

    lowclip_tri = poly!(parent, lowclip_tri, color = lowclip_tri_color,
        strokecolor = :black,
        strokewidth = spinewidth,
        visible = lift(x -> !(isnothing(x) || to_color(x) == to_color(:transparent)), lowclip))[end]
    decorations[:lowclip] = lowclip_tri



    axispoints = lift(barbox, vertical, flipaxisposition) do scenearea,
            vertical, flipaxisposition

        if vertical
            if flipaxisposition
                (bottomright(scenearea), topright(scenearea))
            else
                (bottomleft(scenearea), topleft(scenearea))
            end
        else
            if flipaxisposition
                (topleft(scenearea), topright(scenearea))
            else
                (bottomleft(scenearea), bottomright(scenearea))
            end
        end

    end

    axis = LineAxis(parent, endpoints = axispoints, flipped = flipaxisposition,
        limits = limits, ticklabelalign = ticklabelalign, label = label,
        labelpadding = labelpadding, labelvisible = labelvisible, labelsize = labelsize,
        labelfont = labelfont, ticklabelfont = ticklabelfont, ticks = ticks, tickformat = tickformat,
        ticklabelsize = ticklabelsize, ticklabelsvisible = ticklabelsvisible, ticksize = ticksize,
        ticksvisible = ticksvisible, ticklabelpad = ticklabelpad, tickalign = tickalign,
        tickwidth = tickwidth, tickcolor = tickcolor, spinewidth = spinewidth,
        ticklabelspace = ticklabelspace,
        spinecolor = :transparent, spinevisible = :false, flip_vertical_label = flip_vertical_label)
    decorations[:axis] = axis

    onany(axis.protrusion, vertical, flipaxisposition) do axprotrusion,
            vertical, flipaxisposition


        left, right, top, bottom = 0f0, 0f0, 0f0, 0f0

        if vertical
            if flipaxisposition
                right += axprotrusion
            else
                left += axprotrusion
            end
        else
            if flipaxisposition
                top += axprotrusion
            else
                bottom += axprotrusion
            end
        end

        protrusions[] = GridLayoutBase.RectSides{Float32}(left, right, bottom, top)
    end

    # trigger protrusions with one of the attributes
    vertical[] = vertical[]

    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    LColorbar(parent, layoutobservables, attrs, decorations)
end

function tight_ticklabel_spacing!(lc::LColorbar)
    tight_ticklabel_spacing!(lc.decorations[:axis])
end
