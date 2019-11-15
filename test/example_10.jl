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

    for i in 1:nrows, j in 1:ncols

        scatter!(las[i, j], rand(200, 2) .+ [i j])

        i > 1 && (las[i, j].attributes.titlevisible = false)
        j > 1 && (las[i, j].attributes.ylabelvisible = false)
        j > 1 && (las[i, j].attributes.yticklabelsvisible = false)
        j > 1 && (las[i, j].attributes.yticksvisible = false)
        i < nrows && (las[i, j].attributes.xticklabelsvisible = false)
        i < nrows && (las[i, j].attributes.xticksvisible = false)
        i < nrows && (las[i, j].attributes.xlabelvisible = false)
    end

    linkxaxes!(las...)
    linkyaxes!(las...)

    maingl[0, :] = LayoutedText(scene, text="Super Title", textsize=50)
    maingl[2:end, end+1] = LayoutedText(scene, text="Side Title", textsize=50, rotation=-pi/2)

    nothing
end

save("layout.png", scene)
