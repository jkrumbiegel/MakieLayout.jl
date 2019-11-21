using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000), font="SF Hello");
    screen = display(scene)
    campixel!(scene);

    nrows = 1
    ncols = 1

    maingl = GridLayout(
        nrows, ncols,
        parent = scene,
        colsizes = Auto(false, 1),
        rowsizes = Auto(false, 1),
        alignmode = Outside(30, 30, 30, 30))

    las = [maingl[i, j] = LayoutedAxis(scene, sidelabelvisible=true, sidelabelalign=:center) for i in 1:nrows, j in 1:ncols]

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
        i < nrows && (las[i, j].xlabelvisible = false)
    end

    tl = maingl[0, :] = LayoutedText(scene, text="Super Title", textsize=50)
    stl = maingl[2:end, end+1] = LayoutedText(scene, text="Side Title", textsize=50, rotation=-pi/2)

    slgl = maingl[end+1, 1:end-1] = GridLayout(1, 2)

    slgl[1, 1] = LayoutedText(scene, text="Supertitle Size", halign=:left)
    sl1 = slgl[1, 2] = LayoutedSlider(scene, 30, 1:200)
    on(sl1.slider.value) do val
        tl.attributes.textsize = val
    end

    slgl[2, 1] = LayoutedText(scene, text="Sidetitle Size", halign=:left)
    sl2 = slgl[2, 2] = LayoutedSlider(scene, 30, 1:200)
    on(sl2.slider.value) do val
        stl.attributes.textsize = val
    end

    nothing
end

save("layout.png", scene)
