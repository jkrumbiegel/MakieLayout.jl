using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000));
    screen = display(scene)
    campixel!(scene);

    maingl = GridLayout(
        1, 2;
        parent = scene,
        rowsizes = Relative(1),
        colsizes = [Auto(), Fixed(200)],
        addedcolgaps = Fixed(30),
        alignmode = Outside(30, 30, 30, 30)
    )

    gl = maingl[1, 1] = GridLayout(
        3, 3;
        rowsizes = Relative(1/3),
        colsizes = Auto(),
        addedcolgaps = Fixed(20),
        addedrowgaps = Fixed(20),
        alignmode = Outside()
    )

    las = []
    for i in 1:3, j in 1:3
        # la =
        # al = ProtrusionLayout(gl, la.protrusions, la.bboxnode)
        la = gl[i, j] = LAxis(scene)
        sc = scatter!(
            la,
            rand(100, 2) .* 90 .+ 5,
            color=RGBf0(rand(3)...),
            raw=true, markersize=5)
        push!(las, la)
    end

    # buttons need change in abstractplotting to correctly update frame position

    glside = maingl[1, 2] = GridLayout(7, 1, alignmode=Outside())

    but = glside[1, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Titles")
    on(but.clicks) do c
        for la in las
            la.titlevisible[] = !la.titlevisible[]
        end
    end

    but2 = glside[2, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Labels")
    on(but2.clicks) do c
        for la in las
            la.xlabelvisible[] = !la.xlabelvisible[]
            la.ylabelvisible[] = !la.ylabelvisible[]
        end
    end

    but3 = glside[3, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Ticklabels")
    on(but3.clicks) do c
        for la in las
            la.xticklabelsvisible[] = !la.xticklabelsvisible[]
            la.yticklabelsvisible[] = !la.yticklabelsvisible[]
        end
    end

    but4 = glside[4, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Ticks")
    on(but4.clicks) do c
        with_updates_suspended(maingl) do
            for la in las
                la.xticksvisible[] = !la.xticksvisible[]
                la.yticksvisible[] = !la.yticksvisible[]
            end
        end
    end

    but5 = glside[5, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Tick Align")
    on(but5.clicks) do c
        maingl.block_updates = true
        for la in las
            la.xtickalign[] = la.xtickalign[] == 1 ? 0 : 1
            la.ytickalign[] = la.ytickalign[] == 1 ? 0 : 1
        end
        maingl.block_updates = true
        maingl.needs_update[] = true
    end

    but6 = glside[6, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Grids")
    on(but6.clicks) do c
        for la in las
            la.xgridvisible[] = !la.xgridvisible[]
            la.ygridvisible[] = !la.ygridvisible[]
        end
    end

    but7 = glside[7, 1] = LButton(scene, width = 200, height = 50, label = "Toggle Spines")
    on(but7.clicks) do c
        for la in las
            la.xspinevisible[] = !la.xspinevisible[]
            la.yspinevisible[] = !la.yspinevisible[]
            la.xoppositespinevisible[] = !la.xoppositespinevisible[]
            la.yoppositespinevisible[] = !la.yoppositespinevisible[]
        end
    end
end

map(la -> la.xticklabelpad = 5, las)
map(la -> la.xlabelpadding = 0, las)
map(la -> la.spinewidth = 1, las)
map(la -> la.xticklabelrotation = pi/2, las)
map(la -> la.xticklabelalign = (:right, :center), las)
map(la -> la.xticklabelspace = 50, las)


begin
    begin
        for i in 1:9
            las[i].ylabelvisible[] = false
            las[i].xlabelvisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].yticklabelsvisible[] = false
            las[i].xticklabelsvisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].titlevisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].ylabelvisible[] = true
            las[i].xlabelvisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].yticklabelsvisible[] = true
            las[i].xticklabelsvisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].titlevisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].title[] = "Big\nTitle"
            las[i].ylabel[] = "Big\ny label"
            las[i].xlabel[] = "Big\nx label"
            sleep(0.05)
        end

        for i in 1:9
            las[i].title[] = "Title"
            las[i].ylabel[] = "y label"
            las[i].xlabel[] = "x label"
            sleep(0.05)
        end
    end
    begin
        for i in 1:9
            las[i].ylabelsize[] = 30
            las[i].xlabelsize[] = 30
            las[i].yticklabelsize[] = 30
            las[i].xticklabelsize[] = 30
            sleep(0.05)
        end

        for i in 1:9
            las[i].ylabelsize[] = 20
            las[i].xlabelsize[] = 20
            las[i].yticklabelsize[] = 20
            las[i].xticklabelsize[] = 20
            sleep(0.05)
        end
    end
end
