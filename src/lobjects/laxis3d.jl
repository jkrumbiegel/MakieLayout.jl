using Makie
using GLFW; GLFW.WindowHint(GLFW.FLOATING, 1)
using LinearAlgebra
using StaticArrays

##
scene, layout = layoutscene()
lscene = layout[1, 1] = LScene(scene, scenekw = (center = false, raw = true))
display(scene)

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




limits = Node(FRect3D((-10, -10, -10), (20, 20, 20)))

azim = Node(0.0)
elev = Node(0.0)


view = lift(azim, elev, limits) do a, e, lims
    center = lims.origin .+ 0.5 .* widths(lims)
    dist = maximum(widths(lims)) # should be enough to be outside?
    eyepos = center .+ dist .* normalize(SVector(sin(e) * cos(a), sin(e) * sin(a), cos(e)))

    AbstractPlotting.lookat(eyepos, center, Vec(0.0, 0, 1))
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

    # @show minis
    # @show maxis
    # @show boxmin
    # @show boxmax

    # flipmatrix = [
    #     0 1 0 0
    #     1 0 0 0
    #     0 0 1 0
    #     0 0 0 1
    # ]

    AbstractPlotting.orthographicprojection(boxmin[1], boxmax[1], boxmin[2], boxmax[2], boxmin[3] - 10000, boxmax[3] + 10000) # * flipmatrix
end

projectionview = lift(projection, view) do p, v
    p * v
end

disconnect!(lscene.scene.camera)

on(projectionview) do pv
    camera(lscene.scene).view[] = view[]
    camera(lscene.scene).projection[] = projection[]
    camera(lscene.scene).projectionview[] = pv
end

mousestate = MakieLayout.addmousestate!(lscene.scene)
MakieLayout.onmouseleftdrag(mousestate) do state
    @show state.pos, state.prev
    diff = state.pos .- state.prev
    azim[] -= 0.05 * diff[1]
    elev[] -= 0.05 * diff[2]
end

view[] = view[]


# scatter!(lscene, rand(300, 3) .* 10 .- 5, markersize = 0.2)

x = -10:0.3:10
y = -10:0.3:10
z = 3 .* [sin(x) * cos(y) for x in -10:0.3:10, y in -10:0.3:10]

points = [(x, y, 3 * sin(x) * cos(y)) for x in -10:0.3:10 for y in -10:0.3:10]

using GeometryTypes
function mesh_triangles(ni::Int, nj::Int)
    triangles = Face{3, Int}[]

    n(i, j) = (i - 1) * nj + j

    for i in 1:ni-1, j in 1:nj-1
        push!(triangles, Point(n(i, j), n(i+1, j), n(i, j+1)))
        push!(triangles, Point(n(i+1, j), n(i+1, j+1), n(i, j+1)))
    end

    triangles
end

# AbstractPlotting.to_vertices()


# surface!(lscene, x, y, z, shading = false)
mesh!(lscene, points, mesh_triangles(length(x), length(y)), color = vec(z), shading = false)
wireframe!(lscene,  x, y, z.+0.01, transparency = true, color = (:black, 0.3))

# points = [Point3f0(x, y, sin(x) * cos(y)) for x in -5:5, y in -5:5]
# mesh!(lscene, points, shading = false)

# update_cam!(scene, camera(scene), FRect3D((0, 0, 0), (10, 10, 10f0)))


sl1 = layout[2, 1] = LSlider(scene, range = 0:0.01:2pi)
sl2 = layout[3, 1] = LSlider(scene, range = 0.001:0.01:pi-0.001)

using Observables
on(sl1.value) do v
    azim[] = v
end
on(sl2.value) do v
    elev[] = v
end

showleft = Node(true)
showfront = Node(true)
on(azim) do a
    new_showleft = sin(a) > 0
    new_showfront = cos(a) > 0
    if showleft[] != new_showleft
        showleft[] = new_showleft
    end
    if showfront[] != new_showfront
        showfront[] = new_showfront
    end
end
showbottom = Node(true)
on(elev) do e
    new_showbottom = cos(e) > 0
    if showbottom[] != new_showbottom
        showbottom[] = new_showbottom
    end
end

set_close_to!(sl1, pi/6)
set_close_to!(sl2, pi/6)


xframe = lift(limits, showfront) do lims, showfront
    o = lims.origin
    w = lims.widths
    xquad((o[2], o[3]), (w[2], w[3]), showfront ? minimum(lims)[1] : maximum(lims)[1])
end

yframe = lift(limits, showleft) do lims, showleft
    o = lims.origin
    w = lims.widths
    yquad((o[1], o[3]), (w[1], w[3]), showleft ? minimum(lims)[2] : maximum(lims)[2])
end

zframe = lift(limits, showbottom) do lims, showbottom
    o = lims.origin
    w = lims.widths
    zquad((o[1], o[2]), (w[1], w[2]), showbottom ? minimum(lims)[3] : maximum(lims)[3])
end

framecolor = :black
lines!(lscene, xframe, color = framecolor, linewidth = 1)
lines!(lscene, yframe, color = framecolor, linewidth = 1)
lines!(lscene, zframe, color = framecolor, linewidth = 1)

xtickvalues = lift(limits) do lims
    MakieLayout.locateticks(minimum(lims)[1], maximum(lims)[1], 5)
end

xgridlines = lift(xtickvalues, showleft, showbottom) do xtickvals, showleft, showbottom
    lims = limits[]

    ysame = showleft ? minimum(lims) : maximum(lims)
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

zgridlines = lift(ztickvalues, showleft, showfront) do ztickvals, showleft, showfront
    lims = limits[]

    xsame = showfront ? minimum(lims) : maximum(lims)
    ysame = showleft ? minimum(lims) : maximum(lims)

    segs1 = map(ztickvals) do z
        (Point3f0(minimum(lims)[1], ysame[2], z), Point3f0(maximum(lims)[1], ysame[2], z))
    end
    segs2 = map(ztickvals) do z
        (Point3f0(xsame[1], minimum(lims)[2], z), Point3f0(xsame[1], maximum(lims)[2], z))
    end
    vcat(segs1, segs2)
end

gridcolor = (:black, 0.15)
linesegments!(lscene, xgridlines, color = gridcolor)
linesegments!(lscene, ygridlines, color = gridcolor)
linesegments!(lscene, zgridlines, color = gridcolor)

to_4dim(point::Point3) = Point4(point..., 0)
to_4dim(point::Point2) = Point4(point..., 0, 0)
to_2dim(point::Point4) = Point2(point[1], point[2])

xtickpositions = lift(xgridlines, lscene.scene.px_area, projectionview) do xgrid, area, pview
    oneminusone_space = Ref(pview) .* to_4dim.(last.(xgrid[1:length(xgrid) ÷ 2]))
    screen_space = [((p .+ 1 ).* 0.5) .* area.widths .+ area.origin for p in to_2dim.(oneminusone_space)]
end

ytickpositions = lift(ygridlines, lscene.scene.px_area, projectionview) do ygrid, area, pview
    oneminusone_space = Ref(pview) .* to_4dim.(last.(ygrid[1:length(ygrid) ÷ 2]))
    screen_space = [((p .+ 1 ).* 0.5) .* area.widths .+ area.origin for p in to_2dim.(oneminusone_space)]
end

ztickpositions = lift(zgridlines, lscene.scene.px_area, projectionview) do zgrid, area, pview
    oneminusone_space = Ref(pview) .* to_4dim.(last.(zgrid[1:length(zgrid) ÷ 2]))
    screen_space = [((p .+ 1 ).* 0.5) .* area.widths .+ area.origin for p in to_2dim.(oneminusone_space)]
end
#
annotations!(scene,
    lift((xtv, xtp) -> collect(zip(string.(xtv), xtp)), xtickvalues, xtickpositions),
    align = (:left, :top),
    show_axis = false)

annotations!(scene,
    lift((ytv, ytp) -> collect(zip(string.(ytv), ytp)), ytickvalues, ytickpositions),
    align = (:right, :top),
    show_axis = false)

annotations!(scene,
    lift((ztv, ztp) -> collect(zip(string.(ztv), ztp)), ztickvalues, ztickpositions),
    align = (:right, :top),
    show_axis = false)
nothing
