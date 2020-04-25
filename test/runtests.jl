using MakieLayout
using AbstractPlotting
using Test


@testset "Layoutables constructors" begin
    scene, layout = layoutscene()
    ax = layout[1, 1] = LAxis(scene)
    cb = layout[1, 2] = LColorbar(scene)
    gl2 = layout[2, :] = MakieLayout.GridLayout()
    bu = gl2[1, 1] = LButton(scene)
    sl = gl2[1, 2] = LSlider(scene)

    scat = scatter!(ax, rand(10))
    le = gl2[1, 3] = LLegend(scene, [scat], ["scatter"])

    to = gl2[1, 4] = LToggle(scene)
    te = layout[0, :] = LText(scene, "A super title")
    me = layout[end+1, :] = LMenu(scene, options = ["one", "two", "three"])
end
