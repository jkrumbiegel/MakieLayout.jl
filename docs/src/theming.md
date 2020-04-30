## Theming

Every layoutable object can be themed by adding attributes under a key with
the same name as the layoutable (LAxis, LColorbar, etc.).

```@example
using MakieLayout
using Makie

set_theme!(
    LAxis = (topspinevisible = false, rightspinevisible = false,
        xgridcolor = :blue, ygridcolor = :red),
    LColorbar = (width = 20, height = Relative(0.5))
)

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)
cb = layout[1, 2] = LColorbar(scene)

save("example_theming.png", scene); nothing # hide
```

![example theming](example_theming.png)
