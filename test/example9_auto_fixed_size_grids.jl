using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000), font="SF Hello");
    screen = display(scene)
    campixel!(scene);

    maingl = GridLayout(
        1, 3;
        addedcolgaps = Fixed(0),
        rowsizes = Relative(1),
        parent = scene,
        alignmode = Outside(30, 30, 30, 30)
    )

    maingl[1, 2] = LAxis(scene)
    maingl[1, 3] = LAxis(scene)

    guigl = maingl[1, 1] = GridLayout(1, 3)

    # guigl[1, 1] = LButton(scene, 100, 30, "button")
    guigl[1, 1] = LText(scene, text="HelloWorld", halign=:left)
    guigl[1, 2] = LText(scene, text="Blablo", halign=:left)
    guigl[1, 3] = LButton(scene, width = 120, height = 30, label = "Bliblu")

    guigl[2, 1] = LText(scene, text="Mamama", halign=:left)
    guigl[2, 2] = LText(scene, text="Mimimi", halign=:left)
    guigl[2, 3] = LButton(scene, width = 120, height = 30, label = "Momomo")

    guigl[3, 1] = LText(scene, text="VeerrryLoong", halign=:left)
    guigl[3, 2] = LText(scene, text="Blablo", halign=:left)
    guigl[3, 3] = LButton(scene, width = 120, height = 30, label = "Short")

end
