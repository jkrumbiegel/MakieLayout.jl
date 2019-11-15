using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000), font="SF Hello");
    screen = display(scene)
    campixel!(scene);

    maingl = GridLayout(
        1, 2;
        addedcolgaps = Fixed(20),
        rowsizes = Relative(1),
        parent = scene,
        alignmode = Outside(30, 30, 30, 30)
    )

    maingl[1, 2] = LayoutedAxis(scene)

    guigl = maingl[1, 1] = GridLayout(1, 2)

    t1 = guigl[1, 1] = LayoutedText(scene, text="Hello", halign=:left)

    guigl[1, 2] = LayoutedButton(scene, 100, 30, "button")

    guigl[end+1, 1] = LayoutedText(scene, text="HelloHello", halign=:left)
    guigl[end, 2] = LayoutedButton(scene, 100, 30, "button")
    #
    # guigl[end+1, 1] = LayoutedText(scene, text="Whazzup", halign=:left)
    # guigl[end, 2] = LayoutedButton(scene, 100, 30, "button")

    # guigl[end+1, :] = LayoutedSlider(scene, 30, 0:0.1:50)

end

guigl.addedcolgaps = [Fixed(0)]
t1.attributes.halign = :right
t1.attributes.rotation = 0.0
t1.attributes.padding = (0, 0, 0, 0)
