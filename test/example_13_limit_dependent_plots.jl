using MakieLayout
using Makie

function axhline!(la::LayoutedAxis, y; kwargs...)
    points = lift(la.limits) do lims
        x1 = lims.origin[1]
        x2 = lims.origin[1] + lims.widths[1]
        Point2f0.([(x1, y), (x2, y)])
    end

    lines!(la, points; xautolimit=false, kwargs...)
end

function axvline!(la::LayoutedAxis, x; kwargs...)
    points = lift(la.limits) do lims
        y1 = lims.origin[2]
        y2 = lims.origin[2] + lims.widths[2]
        Point2f0.([(x, y1), (x, y2)])
    end

    lines!(la, points; yautolimit=false, kwargs...)
end

function abline!(la::LayoutedAxis, a, b; kwargs...)
    points = lift(la.limits) do lims
        x1 = lims.origin[1]
        x2 = lims.origin[1] + lims.widths[1]
        Point2f0.([(x1, a * x1 + b), (x2, a * x2 + b)])
    end

    lines!(la, points; xautolimit=false, yautolimit=false, kwargs...)
end

function dynamicfunc!(la::LayoutedAxis, func; n=nothing, kwargs...)

    points = lift(la.limits, la.layoutnodes.computedbbox) do lims, bbox

        if isnothing(n)
            xwidth = width(bbox)
            n = Int(round(xwidth))
        end

        x1 = lims.origin[1]
        x2 = lims.origin[1] + lims.widths[1]
        xs = LinRange(x1, x2, n)
        ys = func.(xs)
        [Point2f0(x, y) for (x, y) in zip(xs, ys)]
    end

    lines!(la, points; xautolimit=false, yautolimit=false, kwargs...)
end

function dynamicimage!(la::LayoutedAxis, func; n=300, kwargs...)
    pixels = lift(la.limits) do lims
        x1, y1 = lims.origin
        x2, y2 = lims.origin .+ lims.widths
        xs = LinRange(x1, x2, n)
        ys = LinRange(y1, y2, n)

        pixels = Float32[func(x, y) for x in xs, y in ys]
    end

    xrange = lift(lims -> lims.origin[1] .+ [0, lims.widths[1]], la.limits)
    yrange = lift(lims -> lims.origin[2] .+ [0, lims.widths[2]], la.limits)

    image!(la, xrange, yrange, pixels; xautolimit=false, yautolimit=false, kwargs...)
end

begin
    scene = Scene(resolution = (1000, 1000));
    screen = display(scene)
    campixel!(scene);

    nrows = 1
    ncols = 1

    maingl = GridLayout(1, 1, parent=scene, alignmode=Outside(30))

    gridgl = maingl[1, 1] = GridLayout(
        nrows, ncols)

    la = gridgl[1, 1] = LayoutedAxis(scene)

    # scatter!(la, rand(100, 2) .* 50, markersize=20)
    axhline!(la, 0)
    axvline!(la, 0)
    abline!(la, 1, 0)

    dynamicfunc!(la, sin, color=:red)
    dynamicfunc!(la, cos, color=:blue)

    nothing
end

# save("layout.png", scene)
