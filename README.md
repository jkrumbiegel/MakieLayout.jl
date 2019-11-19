# MakieLayout.jl

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://jkrumbiegel.github.io/MakieLayout.jl/dev/)

## Purpose

This package brings grid layouts and layoutable 2D axes to Makie.jl. You can create nested grids in which
rows and columns are either of fixed or relative size, in an aspect ratio with
another column or row, or auto inferred if they contain only determinable layout objects.
With these tools you can create any 2D layout you want, while most parameters are instantly
adjustable using Observables, as in Makie.jl.

### Examples

```julia
using MakieLayout
using Makie

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

save("layout.png", scene)
```

![example layout](https://raw.githubusercontent.com/jkrumbiegel/MakieLayout.jl/master/exampleimg/layout.png)

## How it works

Each layout object needs a certain type or certain types of observables when
it gets created. These tell during the layout computation how much space that
object should get within its parent.

Some Layout objects can contain child layout objects (mostly the GridLayout, maybe others).
When added to a parent layout, a child layout connects its own observables to the parent
needs_update observable.
This way, a necessary update can be signaled to the root layout from any child.

Each layout object (maybe not the GridLayout because it doesn't relate directly to actual content)
additionally defines a number of observables when it's created
that correspond to bounding boxes in the window. For example:

    ProtrusionLayout defines
        - one bounding box (that of the inner axis)
        - maybe the outer too if that should be needed

These bounding boxes are connected to whatever the plot objects are that will
depend on the given layout. This way, plot objects don't have to implement any
kind of layout stuff in their inner code, they only need to be created with one
(or two, etc...) bounding box observables and supply the necessary measures for
whatever layout they're supposed to be placed in.

Now, any change to an observable that is in a chain before a layout object will
trigger that layout object, then the parent, and so on, until the root layout calls
solve on itself and calculates all the bounding boxes for its child layouts.
These bounding boxes are connected to the plot objects, so the plots update correctly.

Example:

- Change title font size of an axis
- Title font size is an observable connected to the top protrusion observable of the axis
- The top protrusion is connected to an ProtrusionLayout and triggers its need_update
- The ProtrusionLayout triggers its parent's GridLayout need_update
- The GridLayout triggers its own parent GridLayout
- This GridLayout is the root so it calls solve on itself with the window size
- The top grid is solved
- The second grid is solved
- The ProtrusionLayout is solved
- The ProtrusionLayout updates its inner boundingbox observable
- All plots connected with that axis update because they depend on the boundingbox
