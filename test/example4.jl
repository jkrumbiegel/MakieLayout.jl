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

    lt = maingl[0, :] = LayoutedText(scene, text="Suptitle", textsize=50)
    lt2 = maingl[2:5, 5] = LayoutedText(scene, text="Side Title", textsize=50,
        rotation = -pi/2)
    lt3 = maingl[6, 1:4] = LayoutedText(scene, text="Sub Title", textsize=50)
    lt3 = maingl[2:5, 0] = LayoutedText(scene, text="Left Title", textsize=50,
        rotation=pi/2)
end
