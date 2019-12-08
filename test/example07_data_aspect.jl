using MakieLayout
using Makie

begin
    scene = Scene(resolution = (1000, 1000), font="SF Hello");
    screen = display(scene)
    campixel!(scene);

    nrows = 2
    ncols = 2

    maingl = GridLayout(
        nrows, ncols;
        parent = scene,
        alignmode = Outside(30, 30, 30, 30)
    )

    axes = [
        maingl[i, j] = LAxis(
            scene,
            aspect=DataAspect(),  # make axis the same aspect as the data (images will not be stretched)
            xautolimitmargin=(0, 0), # don't create margins so that the image aligns with the axis spines
            yautolimitmargin=(0, 0)) # same in y
        for i in 1:nrows, j in 1:ncols]

    for i in 1:nrows, j in 1:ncols
        img = rand(rand(300:700), rand(300:700))
        image!(axes[i, j], img)
    end

end
