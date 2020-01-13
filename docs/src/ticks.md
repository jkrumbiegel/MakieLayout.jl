# Ticks

Optimizing tick placement on axes is one of the fundamental problems of data
visualization.  As such, there are many approaches to doing this, ranging from
simple linear tick location to complex optimization functions.  

## The `Tick` Interface

MakieLayout defines an abstract type [`Ticks`](@ref).  To define a custom tick type `MyTickType`, you must first define a struct:
```julia
struct MyTickType <: Tick
    # implementation here
end
```

Then, to satisfy the Tick interface, it is also necessary to define two functions:

`compute_tick_values(ticks::MyTickType, vmin, vmax, pxwidth)`, and `get_tick_labels(ticks::MyTickType, vmin, vmax, pxwidth)`.  

## Tick types in MakieLayout

Currently, there are three defined types of ticks in MakieLayout:

```@docs
AutoLinearTicks
AutoOptimizedTicks
ManualTicks
```
