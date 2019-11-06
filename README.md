MakieLayout

Each layout object needs a certain type or certain types of observables when
it gets created. For example:

    AxisLayout needs
        - Four Float32 Observables (left, right, top, bottom protrusions) (or 1 rect)

    FixedSizeBox needs
        - Four Float32 Observables (width, height, align_h, align_v)

    FixedHeightBox needs
        - Two Float32 Observables (height, align_v)

    GridLayout needs
        - Tons of observables...

    etc...

Some Layout objects can contain child layout objects (mostly the GridLayout, maybe others).
When added to a parent layout, a child layout connects its own observables to the parent
needs_update observable (or whatever).
This way, a necessary update can be signaled to the root layout from any child.

Each layout object (maybe not the GridLayout because it doesn't relate directly to actual content)
additionally defines a number of observables when it's created
that correspond to bounding boxes in the window. For example:

    AxisLayout defines
        - one bounding box (that of the inner axis)
        - maybe the outer too if that should be needed

These bounding boxes are connected to whatever the plot objects are that will
depend on the given layout. This way, plot objects don't have to implement any
kind of layout stuff in their inner code, they only need to be created with one
(or two, etc...) bounding box observables and supply the necessary measures for
whatever layout they're supposed to be placed in.

Now, any change to an observable that is in a chain before a layout object will
trigger that layout object, then the parent, and so on, until the root layout calls
solve on itself and calculates all the bounding boxes for its child layouts.
These bounding boxes are connected to the plot objects, so the plots update correctly.

Example:

Change title font size of an axis
Title font size is an observable connected to the top protrusion observable of the axis
The top protrusion is connected to an AxisLayout and triggers its need_update
The AxisLayout triggers its parent's GridLayout need_update
The GridLayout triggers its own parent GridLayout
This GridLayout is the root so it calls solve on itself with the window size
The top grid is solved
The second grid is solved
The AxisLayout is solved
The AxisLayout updates its inner boundingbox observable
All plots connected with that axis update because they depend on the boundingbox
