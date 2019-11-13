using MakieLayout
using Makie
using KernelDensity
using FreeTypeAbstraction


boldface = newface(expanduser("~/Library/Fonts/SFHelloSemibold.ttf"))

function kdepoly!(la::LayoutedAxis, vec, reverse=false; kwargs...)
    kderesult = kde(vec; npoints=32)

    x = kderesult.x
    y = kderesult.density .* 100 # otherwise numbers are super small

    if reverse
        poly!(la, Point2.(y, x); kwargs...)
    else
        poly!(la, Point2.(x, y); kwargs...)
    end
end

begin
    scene = Scene(resolution = (1000, 1000), font="SF Hello");
    screen = display(scene)
    campixel!(scene);

    la1 = LayoutedAxis(scene)
    la2 = LayoutedAxis(scene)
    la3 = LayoutedAxis(scene)

    linkxaxes!(la1, la2)
    linkyaxes!(la1, la3)

    maingl = GridLayout(1, 1, parent=scene, alignmode=Outside(40), colsizes=Relative(1))

    gl2 = maingl[1, 1] = GridLayout(
        2, 2,
        rowsizes = [Relative(0.2), Relative(0.8)],
        colsizes = [Auto(), Aspect(1, 1)],
        addedrowgaps = [Fixed(10)],
        addedcolgaps = [Fixed(10)])

    gl2[2, 1] = la1
    la1.attributes.titlevisible[] = false

    gl2[1, 1] = la2
    la2.attributes.xlabelvisible[] = false
    la2.attributes.xticklabelsvisible[] = false
    la2.attributes.xticksvisible[] = false
    la2.attributes.titlevisible[] = false
    la2.attributes.ypanlock[] = true
    la2.attributes.yzoomlock[] = true

    gl2[2, 2] = la3
    la3.attributes.ylabelvisible[] = false
    la3.attributes.yticklabelsvisible[] = false
    la3.attributes.yticksvisible[] = false
    la3.attributes.titlevisible[] = false
    la3.attributes.xpanlock[] = true
    la3.attributes.xzoomlock[] = true

    maingl[0, 1] = LayoutedText(scene, text="Auto Limits", font=boldface, textsize=50)

    sleep(3)
    linkeddata = randn(200, 2) .* 15 .+ 50
    green = RGBAf0(0.05, 0.8, 0.3, 0.6)
    scatter!(la1, linkeddata, markersize=3, color=green, show_axis=false)
    sleep(1)
    kdepoly!(la2, linkeddata[:, 1], false, color=green, linewidth=2, show_axis=false)
    sleep(1)
    kdepoly!(la3, linkeddata[:, 2], true, color=green, linewidth=2, show_axis=false)
    sleep(1)

    linkeddata2 = randn(200, 2) .* 20 .+ 70
    red = RGBAf0(0.9, 0.1, 0.05, 0.6)
    scatter!(la1, linkeddata2, markersize=3, color=red, show_axis=false)
    sleep(1)
    kdepoly!(la2, linkeddata2[:, 1], false, color=red, linewidth=2, show_axis=false)
    sleep(1)
    kdepoly!(la3, linkeddata2[:, 2], true, color=red, linewidth=2, show_axis=false)
    sleep(1)

    linkeddata3 = randn(200, 2) .* 25 .+ 100
    blue = RGBAf0(0.05, 0.1, 0.9, 0.6)
    scatter!(la1, linkeddata3, markersize=3, color=blue, show_axis=false)
    sleep(1)
    kdepoly!(la2, linkeddata3[:, 1], false, color=blue, linewidth=2, show_axis=false)
    sleep(1)
    kdepoly!(la3, linkeddata3[:, 2], true, color=blue, linewidth=2, show_axis=false)
end
