using Makie
using MakieLayout


begin
    scene = Scene(camera=campixel!)
    display(scene)

    outergrid = GridLayout(scene; alignmode=Outside(30))

    innergrid = outergrid[1, 1] = GridLayout(3, 3)

    las = innergrid[:, 1] = [LAxis(scene) for i in 1:3]

    alignedgrid1 = innergrid[:, 2] = GridLayout(2, 1; rowsizes=Relative(0.33), valign=:center)
    alignedgrid1[1, 1] = LAxis(scene, yaxisposition=:right, yticklabelalign=(:left, :center))
    alignedgrid1[2, 1] = LAxis(scene)

    alignedgrid2 = innergrid[:, 3] = GridLayout(rowsizes=Relative(0.5); valign=:bottom)
    alignedgrid2[1, 1] = LAxis(scene, xaxisposition=:top, xticklabelalign=(:center, :bottom))

    buttonsgl = innergrid[end+1, :] = GridLayout()

    valigns = (:bottom, :top, :center)

    buttons = buttonsgl[1, 1:3] = [LButton(scene; height=40, label="$v") for v in valigns]

    for (button, align) in zip(buttons, valigns)
        on(button.clicks) do c
            alignedgrid1.valign[] = align
            alignedgrid2.valign[] = align
        end
    end
end
