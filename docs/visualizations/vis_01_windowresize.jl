using Makie
using MakieLayout
using Animations


begin
    container_scene = Scene(camera = campixel!, resolution = (1200, 1200))
    # display(container_scene)

    t = Node(0.0)

    a_width = Animation([1, 7], [1200, 800], sineio(n=2, yoyo=true, postwait=0.5))
    a_height = Animation([2.5, 8.5], [1200, 800], sineio(n=2, yoyo=true, postwait=0.5))

    scene_area = lift(t) do t
        IRect(0, 0, round(Int, a_width(t)), round(Int, a_height(t)))
    end

    scene = Scene(container_scene, scene_area, camera = campixel!)

    rect = poly!(scene, scene_area,
        raw=true, color=RGBf0(0.97, 0.97, 0.97), strokecolor=:transparent, strokewidth=0)[end]

    outer_gl = GridLayout(scene, alignmode = Outside(30))

    inner_gl = outer_gl[1, 1] = GridLayout()

    ax1 = inner_gl[1, 1] = LAxis(scene, xautolimitmargin=(0, 0), yautolimitmargin=(0, 0))
    ax2 = inner_gl[1, 2] = LAxis(scene, xautolimitmargin=(0, 0), yautolimitmargin=(0, 0))
    ax3 = inner_gl[2, 1:2] = LAxis(scene, xautolimitmargin=(0, 0), yautolimitmargin=(0, 0))

    guigl = inner_gl[3, 1:2] = GridLayout()
    b1 = guigl[1, 1] = LButton(scene, label = "prev", width = Auto())
    sl = guigl[1, 2] = LSlider(scene, startvalue = 6, height = 40)
    b2 = guigl[1, 3] = LButton(scene, label = "next", width = Auto())

    data = randn(200, 200) .+ 3 .* sin.((1:200) ./ 20) .* sin.((1:200)' ./ 20)
    h1 = heatmap!(ax1, data)
    h2 = heatmap!(ax2, data, colormap = :blues)
    h3 = heatmap!(ax3, data, colormap = :heat)

    agl1 = gridnest!(inner_gl, 1, 1)
    agl1[1, 2] = LColorbar(scene, h1, width = 30, label = "normal bar")
    agl1[2, 1:2] = LSlider(scene, height = 20, startvalue = 4)
    agl1[3, 1:2] = LSlider(scene, height = 20, startvalue = 5)
    agl1[4, 1:2] = LSlider(scene, height = 20, startvalue = 6)

    agl2 = gridnest!(inner_gl, 1, 2)
    agl2[1, 2] = LColorbar(scene, h2, width = 30, height = Relative(0.66), label = "two thirds bar")
    agl2gl = agl2[2, :] = GridLayout()
    agl2gl[1, 1] = LButton(scene, label = "Run", height = Auto())
    agl2gl[1, 2] = LButton(scene, label = "Start")

    agl3 = gridnest!(inner_gl, 2, 1:2)
    agl3[:, 3] = LColorbar(scene, h3, width = 30, height=200, label = "fixed height bar")
    rowsize!(agl3, 1, Auto(false, 1.0))

    inner_gl[0, :] = LText(scene, text = "MakieLayout", textsize = 50)
end

for ts in 0:1/30:10
    t[] = ts
    sleep(1/60)
end

record(container_scene, "/Users/juliuskrumbiegel/Desktop/layoutdemo.mp4", 0:1/30:9; framerate=30) do ti
    t[] = ti
end
