function default_attributes(::Type{LAxis3D}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        "The height setting of the menu."
        height = Auto()
        "The width setting of the menu."
        width = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The horizontal alignment of the menu in its suggested bounding box."
        halign = :center
        "The vertical alignment of the menu in its suggested bounding box."
        valign = :center
        "The alignment of the menu in its suggested bounding box."
        alignmode = Inside()
        targetlimits = FRect3D((-10, -10, -10), (20, 20, 20))
        azimuth = pi/4
        elevation = 2pi/8
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
    LAxis3D(parent::Scene; bbox = nothing, kwargs...)

LAxis3D has the following attributes:

$(let
    _, docs, defaults = default_attributes(LAxis3D, nothing)
    docvarstring(docs, defaults)
end)
"""
LAxis3D


import LinearAlgebra

function LAxis3D(parent::Scene; bbox = nothing, kwargs...)

    default_attrs = default_attributes(LAxis3D, parent).attributes
    theme_attrs = subtheme(parent, :LAxis3D)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    @extract attrs (halign, valign, azimuth, elevation, targetlimits)

    decorations = Dict{Symbol, Any}()

    layoutobservables = LayoutObservables(LAxis3D, attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
    halign, valign, attrs.alignmode; suggestedbbox = bbox)

    scenearea = lift(IRect2D_rounded, layoutobservables.computedbbox)

    scene = Scene(parent, scenearea, center = false, raw = true)

    # until that's corrected
    limits = lift(identity, targetlimits)

    view = lift(azimuth, elevation, limits) do a, e, lims
        center = lims.origin .+ 0.5 .* widths(lims)
        dist = maximum(widths(lims)) # should be enough to be outside?
        eyepos = center .+ dist .* LinearAlgebra.normalize(Vec3f0(sin(e) * cos(a), sin(e) * sin(a), cos(e)))

        eyeright = LinearAlgebra.cross(Vec(0.0, 0, 1), LinearAlgebra.normalize(eyepos .- center))

        # TODO: fix eyeup so there is no flip at the elevation zero point
        eyeup = LinearAlgebra.cross(eyeright, LinearAlgebra.normalize(eyepos .- center))

        AbstractPlotting.lookat(eyepos, center, -eyeup)
    end

    projection = lift(view) do v
        lims = limits[]
        ox, oy, oz = lims.origin
        wx, wy, wz = lims.widths

        corners = [
            ox          oy          oz        0
            ox          oy          oz + wz   0
            ox          oy + wy     oz        0
            ox          oy + wy     oz + wz   0
            ox + wx     oy          oz        0
            ox + wx     oy          oz + wz   0
            ox + wx     oy + wy     oz        0
            ox + wx     oy + wy     oz + wz   0
        ]

        viewed_corners = (v * corners')'

        boxmin = minimum(viewed_corners, dims = 1)
        boxmax = maximum(viewed_corners, dims = 1)

        dist = boxmax .- boxmin
        minis = boxmin .+ 0.5 .* dist
        maxis = boxmax .- 0.5 .* dist

        boxmin
        boxmax

        AbstractPlotting.orthographicprojection(
            boxmin[1], boxmax[1],
            boxmin[2], boxmax[2],
            boxmin[3] - 10000, boxmax[3] + 10000) # * flipmatrix
    end

    projectionview = lift(projection, view) do p, v
        p * v
    end

    disconnect!(scene.camera)

    on(projectionview) do pv
        camera(scene).view[] = view[]
        camera(scene).projection[] = projection[]
        camera(scene).projectionview[] = pv
    end




    ################################################################

    showright = Node(true)
    showfront = Node(true)
    on(azimuth) do a
        new_showright = sin(a) > 0
        new_showfront = cos(a) > 0
        if showright[] != new_showright
            showright[] = new_showright
        end
        if showfront[] != new_showfront
            showfront[] = new_showfront
        end
    end
    showbottom = Node(true)
    on(elevation) do e
        new_showbottom = cos(e) > 0
        if showbottom[] != new_showbottom
            showbottom[] = new_showbottom
        end
    end

    on(showright -> println("showright ", showright), showright)
    on(showfront -> println("showfront ", showfront), showfront)
    on(showbottom -> println("showbottom ", showbottom), showbottom)


    xframe = lift(limits, showfront) do lims, showfront
        o = lims.origin
        w = lims.widths
        xquad((o[2], o[3]), (w[2], w[3]), showfront ? minimum(lims)[1] : maximum(lims)[1])
    end

    yframe = lift(limits, showright) do lims, showright
        o = lims.origin
        w = lims.widths
        yquad((o[1], o[3]), (w[1], w[3]), showright ? minimum(lims)[2] : maximum(lims)[2])
    end

    zframe = lift(limits, showbottom) do lims, showbottom
        o = lims.origin
        w = lims.widths
        zquad((o[1], o[2]), (w[1], w[2]), showbottom ? minimum(lims)[3] : maximum(lims)[3])
    end

    framecolor = :black
    lines!(scene, xframe, color = framecolor, linewidth = 1)
    lines!(scene, yframe, color = framecolor, linewidth = 1)
    lines!(scene, zframe, color = framecolor, linewidth = 1)

    xtickvalues = lift(limits) do lims
        MakieLayout.locateticks(minimum(lims)[1], maximum(lims)[1], 5)
    end

    xgridlines = lift(xtickvalues, showright, showbottom) do xtickvals, showright, showbottom
        lims = limits[]

        ysame = showright ? minimum(lims) : maximum(lims)
        zsame = showbottom ? minimum(lims) : maximum(lims)

        segs1 = map(xtickvals) do x
            (Point3f0(x, minimum(lims)[2], zsame[3]), Point3f0(x, maximum(lims)[2], zsame[3]))
        end
        segs2 = map(xtickvals) do x
            (Point3f0(x, ysame[2], minimum(lims)[3]), Point3f0(x, ysame[2], maximum(lims)[3]))
        end
        vcat(segs1, segs2)
    end

    ytickvalues = lift(limits) do lims
        MakieLayout.locateticks(minimum(lims)[2], maximum(lims)[2], 5)
    end

    ygridlines = lift(ytickvalues, showfront, showbottom) do ytickvals, showfront, showbottom
        lims = limits[]

        xsame = showfront ? minimum(lims) : maximum(lims)
        zsame = showbottom ? minimum(lims) : maximum(lims)

        segs1 = map(ytickvals) do y
            (Point3f0(minimum(lims)[1], y, zsame[3]), Point3f0(maximum(lims)[1], y, zsame[3]))
        end
        segs2 = map(ytickvals) do y
            (Point3f0(xsame[1], y, minimum(lims)[3]), Point3f0(xsame[1], y, maximum(lims)[3]))
        end
        vcat(segs1, segs2)
    end

    ztickvalues = lift(limits) do lims
        MakieLayout.locateticks(minimum(lims)[3], maximum(lims)[3], 5)
    end

    zgridlines = lift(ztickvalues, showright, showfront) do ztickvals, showright, showfront
        lims = limits[]

        xsame = showfront ? minimum(lims) : maximum(lims)
        ysame = showright ? minimum(lims) : maximum(lims)

        segs1 = map(ztickvals) do z
            (Point3f0(minimum(lims)[1], ysame[2], z), Point3f0(maximum(lims)[1], ysame[2], z))
        end
        segs2 = map(ztickvals) do z
            (Point3f0(xsame[1], minimum(lims)[2], z), Point3f0(xsame[1], maximum(lims)[2], z))
        end
        vcat(segs1, segs2)
    end

    gridcolor = (:black, 0.15)
    linesegments!(scene, xgridlines, color = gridcolor)
    linesegments!(scene, ygridlines, color = gridcolor)
    linesegments!(scene, zgridlines, color = gridcolor)

    to_4dim(point::Point3) = Point4(point..., 0)
    to_4dim(point::Point2) = Point4(point..., 0, 0)
    to_2dim(point::Point4) = Point2(point[1], point[2])

    xtickpositions = lift(xgridlines, scene.px_area, projectionview, showright) do xgrid,
            area, pview, showright

        f = showright ? last : first
        oneminusone_space = Ref(pview) .* to_4dim.(f.(xgrid[1:length(xgrid) ÷ 2]))
        screen_space = [((p .+ 1 ).* 0.5) .* area.widths .+ area.origin for p in to_2dim.(oneminusone_space)]
    end

    ytickpositions = lift(ygridlines, scene.px_area, projectionview, showfront) do ygrid,
            area, pview, showfront

        f = showfront ? last : first
        oneminusone_space = Ref(pview) .* to_4dim.(f.(ygrid[1:length(ygrid) ÷ 2]))
        screen_space = [((p .+ 1 ).* 0.5) .* area.widths .+ area.origin for p in to_2dim.(oneminusone_space)]
    end

    ztickpositions = lift(zgridlines, scene.px_area, projectionview, showfront, showright) do zgrid,
            area, pview, showfront, showright

        f = showfront == showright ? last : first
        oneminusone_space = Ref(pview) .* to_4dim.(f.(zgrid[1:length(zgrid) ÷ 2]))
        screen_space = [((p .+ 1 ).* 0.5) .* area.widths .+ area.origin for p in to_2dim.(oneminusone_space)]
    end
    #
    annotations!(parent,
        lift((xtv, xtp) -> collect(zip(string.(xtv), xtp)), xtickvalues, xtickpositions),
        align = (:left, :top),
        color = :red,
        show_axis = false)

    annotations!(parent,
        lift((ytv, ytp) -> collect(zip(string.(ytv), ytp)), ytickvalues, ytickpositions),
        align = (:right, :top),
        color = :green,
        show_axis = false)

    annotations!(parent,
        lift((ztv, ztp) -> collect(zip(string.(ztv), ztp)), ztickvalues, ztickpositions),
        align = (:right, :top),
        color = :blue,
        show_axis = false)


    ################################################################

    # trigger projection etc
    targetlimits[] = targetlimits[]

    LAxis3D(scene, attrs, layoutobservables, decorations)
end

function xquad(ori, widths, distance)
    Point3f0[
        (distance, ori[1], ori[2]),
        (distance, ori[1] + widths[1], ori[2]),
        (distance, ori[1] + widths[1], ori[2] + widths[2]),
        (distance, ori[1], ori[2] + widths[1]),
        (distance, ori[1], ori[2]),
    ]
end

function yquad(ori, widths, distance)
    Point3f0[
        (ori[1], distance, ori[2]),
        (ori[1] + widths[1], distance, ori[2]),
        (ori[1] + widths[1], distance, ori[2] + widths[2]),
        (ori[1], distance, ori[2] + widths[1]),
        (ori[1], distance, ori[2]),
    ]
end

function zquad(ori, widths, distance)
    Point3f0[
        (ori[1], ori[2], distance),
        (ori[1] + widths[1], ori[2], distance),
        (ori[1] + widths[1], ori[2] + widths[2], distance),
        (ori[1], ori[2] + widths[1], distance),
        (ori[1], ori[2], distance),
    ]
end

function AbstractPlotting.plot!(
        la::LAxis3D, P::AbstractPlotting.PlotFunc,
        attributes::AbstractPlotting.Attributes, args...;
        kw_attributes...)

    plot = AbstractPlotting.plot!(la.scene, P, attributes, args...; kw_attributes...)[end]

    # autolimits!(la)
    plot
end
