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

    la = maingl[1, 1] = LAxis(scene)
    la.attributes.yautolimitmargin = (0f0, 0.05f0)


    poly!(la, BBox(0, 1, 4, 0), color=:blue)
    poly!(la, BBox(1, 2, 7, 0), color=:red)
    poly!(la, BBox(2, 3, 1, 0), color=:green)

    la.attributes.xticks = ManualTicks([0.5, 1.5, 2.5], ["blue", "red", "green"])
    la.attributes.xlabel = "Color"
    la.attributes.ylabel = "Value"
end
