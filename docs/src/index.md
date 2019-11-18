# MakieLayout.jl

## Intro

MakieLayout.jl brings a new 2D Axis object and grid layouting to Makie.jl. You
can build your layouts as grids that are nested within other grids. For grid layouts,
you can specify many visual parameters like row and column widths, the gap sizes
between the rows and columns, or paddings. 2D axes have many more parameters like
titles, labels, ticks, their sizes and colors and alignments, etc. All of these
parameters are Observables and the layout updates itself automatically when you
change them.

As a starting point, here's one example that creates a fairly standard faceting layout
like you might know from ggplot :

```@example
using MakieLayout
using Makie

scene = Scene(resolution = (1200, 900), camera=campixel!)

nrows = 4
ncols = 5

# Create the main GridLayout that is the parent of all other layout objects.
# We set its own parent to the scene it belongs to, this way it will recompute
# itself when the scene size changes, e.g., when you resize the window.
# We also specify the `alignmode` as Outside, which means that everything
# including the decorations of the grid content will fit into the window, with a
# margin of 30px to each side
maingl = GridLayout(
    nrows, ncols,
    parent = scene,
    alignmode = Outside(30, 30, 30, 30))

# create a grid of LayoutedAxis objects and at the same time place them in the
# grid layout with indexing syntax
las = [maingl[i, j] = LayoutedAxis(scene) for i in 1:nrows, j in 1:ncols]

# link x and y axes of all LayoutedAxis objects
linkxaxes!(las...)
linkyaxes!(las...)

for i in 1:nrows, j in 1:ncols

    # plot into the scene that is managed by the LayoutedAxis
    scatter!(las[i, j], rand(200, 2) .+ [i j])

    # remove unnecessary decorations in some of the facets, this will have an
    # effect on the layout as the freed up space will be used to make the axes
    # bigger
    i > 1 && (las[i, j].titlevisible = false)
    j > 1 && (las[i, j].ylabelvisible = false)
    j > 1 && (las[i, j].yticklabelsvisible = false)
    j > 1 && (las[i, j].yticksvisible = false)
    i < nrows && (las[i, j].xticklabelsvisible = false)
    i < nrows && (las[i, j].xticksvisible = false)
    i < nrows && (las[i, j].xlabelvisible = false)
end

# index into the 0th row, thereby adding a new row into the layout and place
# a text object across the full column width as a super title
maingl[0, :] = LayoutedText(scene, text="Super Title", textsize=50)

# place a title on the side by going from the second row to the last (because
# in the first row, there is now the super title) and adding a column to the end
# by indexing one column further than the last index
maingl[2:end, end+1] = LayoutedText(scene, text="Side Title", textsize=50,
    rotation=-pi/2)

save("example_intro.png", scene); nothing # hide
```

![example intro](example_intro.png)
