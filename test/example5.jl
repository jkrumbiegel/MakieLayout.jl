using MakieLayout
using Makie
using FreeTypeAbstraction

boldface = newface(expanduser("~/Library/Fonts/SFHelloSemibold.ttf"))

begin
    scene = Scene(resolution = (1000, 1000), font="SF Hello");
    screen = display(scene)
    campixel!(scene);

    maingl = GridLayout(
        1, 1;
        parent = scene,
        alignmode = Outside(30, 30, 30, 30)
    )

    ni = 2
    nj = 2
    las = Array{LayoutedAxis, 2}(undef, ni, nj)

    for i in 1:ni, j in 1:nj
        las[i, j] = maingl[i, j] = LayoutedAxis(scene, titlefont=boldface, titlesize=20)
    end

    lines!(las[1, 1], 0:0.1:100, sin.((0:0.1:100) ./ 5) .+ 1)
    lines!(las[1, 2], (0:0.1:100) .+ 50, -sin.((0:0.1:100) ./ 5), color=:blue)

    scatter!(las[2, 1], rand(100, 2) .* 200, markersize=4)

    las[2, 2].attributes.xautolimitmargin = (0, 0)
    las[2, 2].attributes.yautolimitmargin = (0, 0)
    image!(las[2, 2], rand(500, 400))

    linkxaxes!(las[1, :]...)
    linkyaxes!(las[1, :]...)

    autolimits!(las[1, 1])
end
