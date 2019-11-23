using MakieLayout
using Makie
using Test

@testset "examples" begin

    println(readdir())
    for file in readdir()
        if startswith(file, "example") && endswith(file, ".jl")
            println("Executing $file")
            include(file)
            sleep(2) # for seeing the result briefly
        end
    end

end
