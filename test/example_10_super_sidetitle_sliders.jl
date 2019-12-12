using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000));
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

    las = [maingl[i, j] = LAxis(scene) for i in 1:nrows, j in 1:ncols]

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

    tl = maingl[0, :] = LText(scene, text="Super Title", padding=(10, 10, 20, 20), textsize=50)
    maingl[1, :] = LRect(scene, strokevisible=false)
    stl = maingl[2:end, end+1] = LText(scene, text="Side Title", textsize=50, rotation=-pi/2)

    slgl = maingl[end+1, 1:end-1] = GridLayout(1, 2)

    slgl[1, 1] = LText(scene, text="Supertitle Size", halign=:left)
    sl1 = slgl[1, 2] = LSlider(scene, height = 30, range = 1:200)
    on(sl1.value) do val
        tl.attributes.textsize = val
    end

    slgl[2, 1] = LText(scene, text="Sidetitle Size", halign=:left)
    sl2 = slgl[2, 2] = LSlider(scene, height = 30, range = 1:200)
    on(sl2.value) do val
        stl.attributes.textsize = val
    end

    nothing
end

# save("layout.png", scene)
