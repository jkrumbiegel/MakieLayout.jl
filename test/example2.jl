using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000), font="SF Hello");
    screen = display(scene)
    campixel!(scene);

    maingl = GridLayout(
        1, 2;
        parent = scene,
        colsizes = [Auto(), Fixed(200)],
        addedcolgaps = Fixed(30),
        alignmode = Outside(30, 30, 30, 30)
    )

    gl = maingl[1, 1] = GridLayout(
        3, 3;
        rowsizes = Relative(1/3),
        colsizes = Auto(),
        addedcolgaps = Fixed(50),
        addedrowgaps = Fixed(20),
        alignmode = Outside()
    )

    las = []
    for i in 1:3, j in 1:3
        # la =
        # al = AxisLayout(gl, la.protrusions, la.bboxnode)
        la = gl[i, j] = LayoutedAxis(scene)
        sc = scatter!(
            la,
            rand(100, 2) .* 90 .+ 5,
            color=RGBf0(rand(3)...),
            raw=true, markersize=5)
        push!(las, la)
    end

    # buttons need change in abstractplotting to correctly update frame position

    glside = maingl[1, 2] = GridLayout(7, 1, alignmode=Outside())

    but = glside[1, 1] = LayoutedButton(scene, 200, 50, "Toggle Titles")
    on(but.button.clicks) do c
        for la in las
            la.attributes.titlevisible[] = !la.attributes.titlevisible[]
        end
    end

    but2 = glside[2, 1] = LayoutedButton(scene, 200, 50, "Toggle Labels")
    on(but2.button.clicks) do c
        for la in las
            la.attributes.xlabelvisible[] = !la.attributes.xlabelvisible[]
            la.attributes.ylabelvisible[] = !la.attributes.ylabelvisible[]
        end
    end

    but3 = glside[3, 1] = LayoutedButton(scene, 200, 50, "Toggle Ticklabels")
    on(but3.button.clicks) do c
        for la in las
            la.attributes.xticklabelsvisible[] = !la.attributes.xticklabelsvisible[]
            la.attributes.yticklabelsvisible[] = !la.attributes.yticklabelsvisible[]
        end
    end

    but4 = glside[4, 1] = LayoutedButton(scene, 200, 50, "Toggle Ticks")
    on(but4.button.clicks) do c
        t1 = time()
        with_updates_suspended(maingl) do
            for la in las
                la.attributes.xticksvisible[] = !la.attributes.xticksvisible[]
                la.attributes.yticksvisible[] = !la.attributes.yticksvisible[]
            end
        end
        println(time() - t1)
    end

    but5 = glside[5, 1] = LayoutedButton(scene, 200, 50, "Toggle Tick Align")
    on(but5.button.clicks) do c
        t1 = time()
        maingl.block_updates = true
        for la in las
            la.attributes.xtickalign[] = la.attributes.xtickalign[] == 1 ? 0 : 1
            la.attributes.ytickalign[] = la.attributes.ytickalign[] == 1 ? 0 : 1
        end
        maingl.block_updates = true
        maingl.needs_update[] = true
        println(time() - t1)
    end

    but6 = glside[6, 1] = LayoutedButton(scene, 200, 50, "Toggle Grids")
    on(but6.button.clicks) do c
        for la in las
            la.attributes.xgridvisible[] = !la.attributes.xgridvisible[]
            la.attributes.ygridvisible[] = !la.attributes.ygridvisible[]
        end
    end
end


begin
    begin
        for i in 1:9
            las[i].attributes.ylabelvisible[] = false
            las[i].attributes.xlabelvisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.yticklabelsvisible[] = false
            las[i].attributes.xticklabelsvisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.titlevisible[] = false
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.ylabelvisible[] = true
            las[i].attributes.xlabelvisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.yticklabelsvisible[] = true
            las[i].attributes.xticklabelsvisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.titlevisible[] = true
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.title[] = "Big\nTitle"
            las[i].attributes.ylabel[] = "Big\ny label"
            las[i].attributes.xlabel[] = "Big\nx label"
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.title[] = "Title"
            las[i].attributes.ylabel[] = "y label"
            las[i].attributes.xlabel[] = "x label"
            sleep(0.05)
        end
    end
    begin
        for i in 1:9
            las[i].attributes.ylabelsize[] = 30
            las[i].attributes.xlabelsize[] = 30
            las[i].attributes.yticklabelsize[] = 30
            las[i].attributes.xticklabelsize[] = 30
            sleep(0.05)
        end

        for i in 1:9
            las[i].attributes.ylabelsize[] = 20
            las[i].attributes.xlabelsize[] = 20
            las[i].attributes.yticklabelsize[] = 20
            las[i].attributes.xticklabelsize[] = 20
            sleep(0.05)
        end
    end
end
