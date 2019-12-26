using Makie
using MakieLayout


begin
    scene = Scene(camera=campixel!)
    screen = display(scene)

    bbox = lift(scene.px_area) do a
        BBox(left(a) + 100, right(a) - 100, bottom(a) + 100, top(a) - 100)
    end

    poly!(scene, bbox, color=RGBAf0(0.1, 0.1, 0.8, 0.2), raw=true)

    bottomleft(bbox) = Point2f0(left(bbox), bottom(bbox))
    topleft(bbox) = Point2f0(left(bbox), top(bbox))
    bottomright(bbox) = Point2f0(right(bbox), bottom(bbox))
    topright(bbox) = Point2f0(right(bbox), top(bbox))

    topline(bbox) = (topleft(bbox), topright(bbox))
    bottomline(bbox) = (bottomleft(bbox), bottomright(bbox))
    leftline(bbox) = (bottomleft(bbox), topleft(bbox))
    rightline(bbox) = (bottomright(bbox), topright(bbox))

    xlim = lift(x -> MakieLayout.limits(x, 1), bbox)
    ylim = lift(x -> MakieLayout.limits(x, 2), bbox)

    ax_b = MakieLayout.LineAxis(scene, endpoints=lift(bottomline, bbox), extents=xlim)
    ax_t = MakieLayout.LineAxis(scene, endpoints=lift(topline, bbox), flipped=true,
        ticklabelalign=(:center, :bottom))
    ax_l = MakieLayout.LineAxis(scene, endpoints=lift(leftline, bbox),
        ticklabelalign=(:right, :center))
    ax_r = MakieLayout.LineAxis(scene, endpoints=lift(rightline, bbox), flipped=true,
        ticklabelalign=(:left, :center))

end

resize!(screen, 600, 600)
