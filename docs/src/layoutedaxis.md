## LAxis

This object represents a 2D axis that has many functions to make it more convenient
to use with layouts. For a grid layout, the axis is a rectangle whose size is not
yet determined, which has "protrusions" sticking out its sides. Those protrusions
are the axis decorations like labels, ticks and titles. The protrusions only change
if you change something about the axis attributes, but they stay the same when
the layout is resized. Therefore, the main axis area will always be determined
by the remaining space after the protrusions are subtracted.

The axis interacts in two directions with the layout. When the size of one of its
protrusions changes, this will notify any associated ProtrusionLayout object. This will
then notify its parent GridLayout, and so on, until the full layout is recomputed.
After that's done, the ProtrusionLayout will have received a new bounding box in which
to place its content. The LAxis has a bounding box node which determines
the borders of the central plot area. This is now updated and the axis' subscene
is adjusted to its new size. All axis decorations also update their positions.


```@example
using MakieLayout
using Makie
using Animations

scene = Scene(resolution = (600, 600), camera=campixel!)

maingl = GridLayout(
    2, 2,
    parent = scene,
    alignmode = Outside(30, 30, 30, 30))

las = [maingl[i, j] = LAxis(scene) for i in 1:2, j in 1:2]

a_title = Animation([0, 2], [30.0, 50.0], sineio(n=2, yoyo=true, prewait=0.2))
a_xlabel = Animation([2, 4], [20.0, 40.0], sineio(n=2, yoyo=true, prewait=0.2))
a_ylabel = Animation([4, 6], [20.0, 40.0], sineio(n=2, yoyo=true, prewait=0.2))

record(scene, "example_protrusion_changes.mp4", 0:1/25:6) do t

    las[1, 1].titlesize = a_title(t)
    las[1, 1].xlabelsize = a_xlabel(t)
    las[1, 1].ylabelsize = a_ylabel(t)

end

nothing # hide
```

![protrusion changes](example_protrusion_changes.mp4)

## Hiding axis decorations

Hiding axis decorations frees up the space for them in the layout if there
are no other protrusions sticking into the same column or row gap that prevent
enlarging the axis area. This makes it easy to achieve tight layouts that don't
waste space. In this example, we set the column and row gaps to zero, so we can
see the shrinking white space better.

```@example
using MakieLayout
using Makie

scene = Scene(resolution = (600, 600), camera=campixel!)

maingl = GridLayout(
    2, 2,
    parent = scene,
    addedcolgaps = Fixed(0),
    addedrowgaps = Fixed(0),
    alignmode = Outside(30, 30, 30, 30))

las = [maingl[i, j] = LAxis(scene) for j in 1:2, i in 1:2]

record(scene, "example_hiding_decorations.mp4", framerate=3) do io

    recordframe!(io)
    for la in las
        la.titlevisible = false
        recordframe!(io)
    end
    for la in las
        la.xlabelvisible = false
        recordframe!(io)
    end
    for la in las
        la.ylabelvisible = false
        recordframe!(io)
    end
    for la in las
        la.xticklabelsvisible = false
        recordframe!(io)
    end
    for la in las
        la.yticklabelsvisible = false
        recordframe!(io)
    end
    for la in las
        la.xticksvisible = false
        recordframe!(io)
    end
    for la in las
        la.yticksvisible = false
        recordframe!(io)
    end
    for la in las
        la.rightspinevisible = false
        la.leftspinevisible = false
        la.bottomspinevisible = false
        la.topspinevisible = false
        recordframe!(io)
    end
end

nothing # hide
```

![hiding decorations](example_hiding_decorations.mp4)

## Axis aspect ratios

If you're plotting images, you might want to force a specific aspect ratio
of an axis, so that the images are not stretched. The default is that an axis
uses all of the available space in the layout. You can use `AxisAspect` and
`DataAspect` to control the aspect ratio. For example, `AxisAspect(1)` forces a
square axis and `AxisAspect(2)` results in a rectangle with a width of two
times the height.
`DataAspect` uses the currently chosen axis limits and brings the axes into the
same aspect ratio. This is the easiest to use with images.
A different aspect ratio can only reduce the axis space that is being used, also
it necessarily has to break the layout a little bit.


```@example
using MakieLayout
using Makie
using FileIO
using Random # hide
Random.seed!(1) # hide

scene = Scene(resolution = (1200, 900), camera=campixel!)

maingl = GridLayout(
    2, 3,
    parent = scene,
    alignmode = Outside(30, 30, 30, 30))

las = [maingl[i, j] = LAxis(scene,
    xautolimitmargin=(0, 0), yautolimitmargin=(0, 0)) for i in 1:2, j in 1:3]

img = reverse(load("cow.png"), dims=1)'

for la in las
    image!(la, img)
end

las[1, 1].title = "Default"

las[1, 2].title = "DataAspect"
las[1, 2].aspect = DataAspect()

las[1, 3].title = "AxisAspect(418/348)"
las[1, 3].aspect = AxisAspect(418/348)

las[2, 1].title = "AxisAspect(1)"
las[2, 1].aspect = AxisAspect(1)

las[2, 2].title = "AxisAspect(2)"
las[2, 2].aspect = AxisAspect(2)

las[2, 3].title = "AxisAspect(0.5)"
las[2, 3].aspect = AxisAspect(0.5)

save("example_axis_aspects.png", scene) # hide
nothing # hide
```

![axis aspects](example_axis_aspects.png)
