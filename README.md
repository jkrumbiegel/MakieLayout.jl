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

linkxaxes!(las...)
linkyaxes!(las...)

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

maingl[0, :] = LayoutedText(scene, text="Super Title", textsize=50)
maingl[2:end, end+1] = LayoutedText(scene, text="Side Title", textsize=50, rotation=-pi/2)

save("layout.png", scene)
```

![example layout](https://raw.githubusercontent.com/jkrumbiegel/MakieLayout.jl/master/exampleimg/layout.png)
