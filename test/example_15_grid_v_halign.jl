using Makie
using MakieLayout


begin
    scene = Scene(camera=campixel!)
    display(scene)

    outergrid = GridLayout(scene; alignmode=Outside(30))

    innergrid = outergrid[1, 1] = GridLayout(3, 3)

    las = [innergrid[i, 1] = LayoutedAxis(scene) for i in 1:3]

    alignedgrid1 = innergrid[:, 2] = GridLayout(2, 1; rowsizes=Relative(0.33), valign=:center)
    alignedgrid1[1, 1] = LayoutedAxis(scene)
    alignedgrid1[2, 1] = LayoutedAxis(scene)

    alignedgrid2 = innergrid[:, 3] = GridLayout(rowsizes=Relative(0.5); valign=:bottom)
    alignedgrid2[1, 1] = LayoutedAxis(scene)
end
