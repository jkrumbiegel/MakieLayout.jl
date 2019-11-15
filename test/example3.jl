using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000), font="SF Hello");
    screen = display(scene)
    campixel!(scene);

    maingl = GridLayout(
        1, 1;
        parent = scene,
        alignmode = Outside(30, 30, 30, 30)
    )

    las = Array{LayoutedAxis, 2}(undef, 4, 4)

    for i in 1:4, j in 1:4
        las[i, j] = maingl[i, j] = LayoutedAxis(scene)
    end
end

las[4, 1].attributes.aspect = AxisAspect(1)
las[4, 2].attributes.aspect = AxisAspect(2)
las[4, 3].attributes.aspect = AxisAspect(0.5)
las[4, 4].attributes.aspect = nothing
las[1, 1].attributes.maxsize = (Inf, Inf)
las[1, 2].attributes.aspect = nothing
las[1, 3].attributes.aspect = nothing

begin
    subgl = nest_content_into_gridlayout!(maingl, 1, 1)
    cb1 = subgl[:, 2] = LayoutedColorbar(scene)
    subgl.colsizes[2] = Relative(0.1)
    cb1.attributes.aspect = AxisAspect(1/10)
    maingl.needs_update[] = true

    # sleep(2)

    subgl2 = nest_content_into_gridlayout!(maingl, 1:2, 1:2)
    cb2 = subgl2[:, 3] = LayoutedColorbar(scene)
    subgl2.colsizes[3] = Relative(0.1)
    cb2.attributes.aspect = AxisAspect(1/10)
    maingl.needs_update[] = true

    # sleep(2)

    subgl3 = nest_content_into_gridlayout!(maingl, 1:3, 1:3)
    cb3 = subgl3[:, 4] = LayoutedColorbar(scene)
    subgl3.colsizes[4] = Relative(0.1)
    cb3.attributes.aspect = AxisAspect(1/10)
    maingl.needs_update[] = true

    # sleep(2)

    subgl4 = nest_content_into_gridlayout!(maingl, 1:4, 1:4)
    cb4 = subgl4[:, 5] = LayoutedColorbar(scene)
    subgl4.colsizes[5] = Relative(0.1)
    cb4.attributes.aspect = AxisAspect(1/10)
    maingl.needs_update[] = true

    # sleep(2)

end
