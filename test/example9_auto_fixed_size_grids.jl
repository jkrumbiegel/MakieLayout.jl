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

    maingl[1, 2] = LayoutedAxis(scene)
    maingl[1, 3] = LayoutedAxis(scene)

    guigl = maingl[1, 1] = GridLayout(1, 3)

    # guigl[1, 1] = LayoutedButton(scene, 100, 30, "button")
    guigl[1, 1] = LayoutedText(scene, text="HelloWorld", halign=:left)
    guigl[1, 2] = LayoutedText(scene, text="Blablo", halign=:left)
    guigl[1, 3] = LayoutedButton(scene, 120, 30, "Bliblu")

    guigl[2, 1] = LayoutedText(scene, text="Mamama", halign=:left)
    guigl[2, 2] = LayoutedText(scene, text="Mimimi", halign=:left)
    guigl[2, 3] = LayoutedButton(scene, 120, 30, "Momomo")

    guigl[3, 1] = LayoutedText(scene, text="VeerrryLoong", halign=:left)
    guigl[3, 2] = LayoutedText(scene, text="Blablo", halign=:left)
    guigl[3, 3] = LayoutedButton(scene, 120, 30, "Short")

end

guigl.addedcolgaps = [Fixed(0)]
t1.attributes.halign = :right
t1.attributes.rotation = 0.0
t1.attributes.padding = (0, 0, 0, 0)
