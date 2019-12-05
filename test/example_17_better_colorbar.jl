using Makie
using MakieLayout


begin
    scene = Scene(camera=campixel!)
    screen = display(scene)

    outergrid = GridLayout(scene; alignmode=Outside(30))

    innergrid = outergrid[1, 1] = GridLayout(2, 2)

    las = innergrid[:, :] = [
        LAxis(scene, xautolimitmargin=(0, 0), yautolimitmargin=(0, 0))
        for i in 1:2, j in 1:2]

    xs = LinRange(0, 3, 100)
    ys = LinRange(0, 3, 100)
    vals = [sin(x * y) for x in xs, y in ys]

    gl1 = nest_content_into_gridlayout!(innergrid, 1, 1)

    hm1 = heatmap!(las[1, 1], vals, colormap=:viridis)
    cb1 = gl1[1, 2] = LColorbar(scene, hm1, width=30f0,
        height=Relative(0.66), alignment=(:center, :center), label = "amplitude",
        ticklabelspace = 60f0)

    gl2 = nest_content_into_gridlayout!(innergrid, 1, 2)

    hm2 = heatmap!(las[1, 2], vals, colormap=:heat)

    gl2[2, 1] = LSlider(scene, height = 30, range = 0:100)


    gl3 = nest_content_into_gridlayout!(innergrid, 2, 1)

    las[2, 1].titlevisible = false
    hm3 = heatmap!(las[2, 1], vals, colormap=:inferno)
    cb3 = gl3[0, 1] = LColorbar(scene, hm3, vertical = false,
        flipaxisposition=true, ticklabelalign = (:center, :bottom), height=30f0,
        label = "amplitude")

    gl4 = nest_content_into_gridlayout!(innergrid, 2, 2)

    las[2, 2].yaxisposition = :right
    las[2, 2].yticklabelalign = (:left, :center)

    hm4 = heatmap!(las[2, 2], vals, colormap=:rainbow)
    cb4 = gl4[1, 0] = LColorbar(scene, hm4,
        flipaxisposition = false, ticklabelalign = (:right, :center), width=30f0,
        label = "amplitude", ticklabelspace=60)

    innergrid[0, :] = LText(scene, text="Colorbars", textsize=50)

    cb2 = innergrid[0, :] = LColorbar(scene, hm2, vertical = false,
        flipaxisposition=false, ticklabelalign = (:center, :top), height=30f0,
        alignment=(:center, :center), label = "amplitude")
end
