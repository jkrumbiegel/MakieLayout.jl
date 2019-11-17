## Nesting grids

Grids can be nested inside other grids, and so on, to arbitrary depths. The top
grid's parent should be the scene in which the layout is placed. When you place
a grid inside another grid, that grid is automatically made its parent. Grids
also are by default set to alignmode Inside which means that the content edges
are aligned to the grid's bounding box, excluding the outer protrusions. This way,
plots in nested grids are nicely aligned along their spines.

```@example
using MakieLayout
using Makie

scene = Scene(resolution = (1200, 900), camera=campixel!)

maingl = GridLayout(
    1, 2,
    parent = scene,
    alignmode = Outside(30, 30, 30, 30))

subgl_left = maingl[1, 1] = GridLayout(2, 2)

for i in 1:2, j in 1:2
    subgl_left[i, j] = LayoutedAxis(scene)
end

subgl_right = maingl[1, 2] = GridLayout(3, 1)

for i in 1:3
    subgl_right[i, 1] = LayoutedAxis(scene)
end

save("example_nested_grids.png", scene); nothing # hide
```

![example nested grids](example_nested_grids.png)

## Grid alignment

Here you can see the difference between the align modes Outside with and without
margins and the Inside alignmode. Only the standard Inside mode aligns the axis
spines of the contained axes nicely. The Outside mode is mostly useful for the
main GridLayout so that there some space between the window edges and the plots.
You can see that the normal axis looks the same as the one placed inside the
grid with Inside alignment, and they are both effectively aligned exactly the same.

```@example
using MakieLayout
using Makie

scene = Scene(resolution = (1200, 1200), camera=campixel!)

maingl = GridLayout(
    3, 2,
    parent = scene,
    alignmode = Outside(30, 30, 30, 30))

maingl[1, 1] = LayoutedAxis(scene, title="No grid layout")
maingl[2, 1] = LayoutedAxis(scene, title="No grid layout")
maingl[3, 1] = LayoutedAxis(scene, title="No grid layout")

subgl_1 = maingl[1, 2] = GridLayout(1, 1, alignmode=Inside())
subgl_2 = maingl[2, 2] = GridLayout(1, 1, alignmode=Outside())
subgl_3 = maingl[3, 2] = GridLayout(1, 1, alignmode=Outside(50))

subgl_1[1, 1] = LayoutedAxis(scene, title="Inside")
subgl_2[1, 1] = LayoutedAxis(scene, title="Outside")
subgl_3[1, 1] = LayoutedAxis(scene, title="Outside(50)")

save("example_grid_alignment.png", scene); nothing # hide
```

![example grid alignment](example_grid_alignment.png)

## Spanned Grid Content

Elements in a grid layout can span multiple rows and columns. You can specify
them with the range syntax and colons for the full width or height. You can
also use end to specify the last row or column.

```@example
using MakieLayout
using Makie

scene = Scene(resolution = (1200, 1200), camera=campixel!)

maingl = GridLayout(
    4, 4,
    parent = scene,
    alignmode = Outside(30, 30, 30, 30))

maingl[1, 1:2] = LayoutedAxis(scene, title="[1, 1:2]")
maingl[2:4, 1:2] = LayoutedAxis(scene, title="[2:4, 1:2]")
maingl[:, 3] = LayoutedAxis(scene, title="[:, 3]")
maingl[1:3, end] = LayoutedAxis(scene, title="[1:3, end]")
maingl[end, end] = LayoutedAxis(scene, title="[end, end]")

save("example_spanned_grid_content.png", scene); nothing # hide
```

![spanned grid content](example_spanned_grid_content.png)

## Indexing outside of a grid layout

If you index outside of the current range of a grid layout, you do not get an
error. Instead, the layout automatically resizes to contain the new indices.
This is very useful if you want to iteratively build a layout, or add super or
side titles.

```@example
using MakieLayout
using Makie

scene = Scene(resolution = (1200, 1200), camera=campixel!)

maingl = GridLayout(
    1, 1,
    parent = scene,
    alignmode = Outside(30, 30, 30, 30))


maingl[1, 1] = LayoutedAxis(scene)
for i in 1:3
    maingl[:, end+1] = LayoutedAxis(scene)
    maingl[end+1, :] = LayoutedAxis(scene)
end

maingl[0, :] = LayoutedText(scene, text="Super Title", textsize=50)
maingl[end+1, :] = LayoutedText(scene, text="Sub Title", textsize=50)
maingl[2:end-1, 0] = LayoutedText(scene, text="Left Text", textsize=50,
    rotation=pi/2)
maingl[2:end-1, end+1] = LayoutedText(scene, text="Right Text", textsize=50,
    rotation=-pi/2)

save("example_indexing_outside_grid.png", scene); nothing # hide
```

![indexing outside grid](example_indexing_outside_grid.png)

## Column and row sizes

You can manipulate the sizes of rows and columns in a grid. The choices are
between fixed widths in pixels, relative widths in fractions of one, aspect
ratio widths that are relative to a selected row or column, and auto widths.
Auto widths depend on the content of the row or column. Some elements like
LayoutedText have a determinable width or height. If there are single-span
elements in a row that have a determinable height and the row's height is set
to auto, it will assume the largest height of all determinable elements it contains.
This is very useful for placement of text, or other GUI elements like buttons
and sliders. If a row or column does not have a determinable height or width,
it defaults to an equal share of the remaining space with all other auto rows or
columns. You can adjust the ratio of this share with the Integer argument of the
Auto struct.

```@example
using MakieLayout
using Makie

scene = Scene(resolution = (1200, 900), camera=campixel!)

maingl = GridLayout(
    5, 5,
    parent = scene,
    colsizes = [Fixed(200), Relative(0.25), Auto(), Auto(), Auto(2)],
    rowsizes = [Fixed(100), Relative(0.25), Aspect(2, 1), Auto(), Auto()],
    alignmode = Outside(30, 30, 30, 30))


for i in 1:5, j in 1:5
    if i == 5 && j == 3
        maingl[i, j] = LayoutedText(scene, text="My Size is Inferred")
    else
        maingl[i, j] = LayoutedAxis(scene, titlevisible=false,
            xlabelvisible=false, ylabelvisible=false, xticklabelsvisible=false,
            yticklabelsvisible=false)
    end
end

save("example_row_col_sizes.png", scene); nothing # hide
```

![row col sizes](example_row_col_sizes.png)
