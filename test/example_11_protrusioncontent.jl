using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000));
    screen = display(scene)
    campixel!(scene);

    nrows = 4
    ncols = 4

    maingl = GridLayout(1, 1, parent=scene, alignmode=Outside(30))

    gridgl = maingl[1, 1] = GridLayout(
        nrows, ncols)

    las = [gridgl[i, j] = LayoutedAxis(scene) for i in 1:nrows, j in 1:ncols]

    linkxaxes!(las...)
    linkyaxes!(las...)

    for i in 1:nrows, j in 1:ncols

        scatter!(las[i, j], rand(200, 2) .+ [i j], markersize=20, color=(:black, 0.3))

        i > 1 && (las[i, j].titlevisible = false)
        j > 1 && (las[i, j].ylabelvisible = false)
        j > 1 && (las[i, j].yticklabelsvisible = false)
        j > 1 && (las[i, j].yticksvisible = false)
        i < nrows && (las[i, j].xticklabelsvisible = false)
        i < nrows && (las[i, j].xticksvisible = false)
        las[i, j].xlabelvisible = false
    end

    gridgl[:, end, Right()] = LayoutedText(scene, text="Side Protrusion", rotation=-pi/2, padding=(20, 0, 0, 0), halign=:right)
    gridgl[end, :, Bottom()] = LayoutedText(scene, text="x label", padding=(0, 0, 50, 0), valign=:bottom)

    maingl[2, 1] = LayoutedAxis(scene)
    maingl[:, 2] = LayoutedAxis(scene)

    gridgl[:, :, TopLeft()] = LayoutedText(scene, text="A", valign=:top, halign=:left, textsize=50, padding=(0, 30, 30, 0))
    maingl[2, 1, TopLeft()] = LayoutedText(scene, text="B", valign=:top, halign=:left, textsize=50, padding=(0, 30, 30, 0))
    maingl[:, 2, TopLeft()] = LayoutedText(scene, text="C", valign=:top, halign=:left, textsize=50, padding=(0, 30, 30, 0))

    tl = maingl[0, :] = LayoutedText(scene, text="Super Title", textsize=50)
    stl = maingl[2:end, end+1] = LayoutedText(scene, text="Side Title", textsize=50, rotation=-pi/2)

    slgl = maingl[end+1, 1:end-1] = GridLayout(1, 2)

    slgl[1, 1] = LayoutedText(scene, text="Supertitle Size", halign=:left)
    sl1 = slgl[1, 2] = LayoutedSlider(scene, height = 30, range = 1:200)
    on(sl1.value) do val
        tl.attributes.textsize = val
    end

    slgl[2, 1] = LayoutedText(scene, text="Sidetitle Size", halign=:left)
    sl2 = slgl[2, 2] = LayoutedSlider(scene, height = 30, range = 1:200)
    on(sl2.value) do val
        stl.attributes.textsize = val
    end

    nothing
end

# save("layout.png", scene)
