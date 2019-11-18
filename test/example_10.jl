using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000), font="SF Hello");
    screen = display(scene)
    campixel!(scene);

    nrows = 4
    ncols = 5

    maingl = GridLayout(
        nrows, ncols,
        parent = scene,
        alignmode = Outside(30, 30, 30, 30))

    las = [maingl[i, j] = LayoutedAxis(scene) for i in 1:nrows, j in 1:ncols]

    linkxaxes!(las...)
    linkyaxes!(las...)

    for i in 1:nrows, j in 1:ncols

        scatter!(las[i, j], rand(200, 2) .+ [i j])

        i > 1 && (las[i, j].titlevisible = false)
        j > 1 && (las[i, j].ylabelvisible = false)
        j > 1 && (las[i, j].yticklabelsvisible = false)
        j > 1 && (las[i, j].yticksvisible = false)
        i < nrows && (las[i, j].xticklabelsvisible = false)
        i < nrows && (las[i, j].xticksvisible = false)
        i < nrows && (las[i, j].xlabelvisible = false)
    end

    maingl[0, :] = LayoutedText(scene, text="Super Title", textsize=50)
    maingl[2:end, end+1] = LayoutedText(scene, text="Side Title", textsize=50, rotation=-pi/2)

    nothing
end

save("layout.png", scene)
