using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000));
    screen = display(scene)
    campixel!(scene);

    maingl = GridLayout(
        1, 1;
        parent = scene,
        alignmode = Outside(30, 30, 30, 30)
    )

    las = Array{LAxis, 2}(undef, 4, 4)

    for i in 1:4, j in 1:4
        las[i, j] = maingl[i, j] = LAxis(scene)
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
    subgl = gridnest!(maingl, 1, 1)
    cb1 = subgl[:, 2] = LColorbar(scene, width=30, height=Relative(0.66))
    sleep(0.5)

    subgl2 = gridnest!(maingl, 1:2, 1:2)
    cb2 = subgl2[:, 3] = LColorbar(scene, width=30, height=Relative(0.66))
    sleep(0.5)

    subgl3 = gridnest!(maingl, 1:3, 1:3)
    cb3 = subgl3[:, 4] = LColorbar(scene, width=30, height=Relative(0.66))
    sleep(0.5)

    subgl4 = gridnest!(maingl, 1:4, 1:4)
    cb4 = subgl4[:, 5] = LColorbar(scene, width=30, height=Relative(0.66))
    sleep(0.5)

end
