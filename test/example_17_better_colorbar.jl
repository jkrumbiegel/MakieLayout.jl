using Makie
using MakieLayout


begin
    scene = Scene(camera=campixel!)
    screen = display(scene)

    outergrid = GridLayout(scene; alignmode=Outside(30))

    innergrid = outergrid[1, 1] = GridLayout(2, 2)

    las = innergrid[:, :] = [LayoutedAxis(scene) for i in 1:2, j in 1:2]

    gl1 = nest_content_into_gridlayout!(innergrid, 1, 1)

    gl1[1, 2] = LayoutedColorbar(scene)
    colsize!(gl1, 2, Fixed(50))

    gl1[2, 1] = LayoutedColorbar(scene, vertical = false, flipaxisposition=false,
        ticklabelalign = (:center, :top))
    rowsize!(gl1, 2, Fixed(50))


end

MakieLayout.protrusion(gl1, MakieLayout.Right())
