## How layouting works

The goal of MakieLayout is that all elements placed in a scene fit into the
window, fill the available space, and are nicely aligned relative to each other.
This works by using `GridLayout` objects that determine how wide their rows and
columns should be given their content elements.

Content elements have inner widths and heights, as well as four protrusions, that tell
how far supporting content (like axis decorations) sticks out from the main part.
The protrusions are meant to stick into the gaps between grid cells, and not every
element has meaningful protrusions. They are mostly meant to allow for alignment
of axes along their spines.

Each element in a layout should have a couple of nodes that support the layout
computations.
- Suggested bounding box
- Computed bounding box
- Auto-determined width and height
- Computed width and height
- Protrusions

### Suggested bounding box

This is the bounding box that is suggested to the element. Depending on the
settings of the element, it can choose to align perfectly with this bounding box
or, if its actual dimensions differ, how it should align inside that rectangle.
A small `LText` can for example be aligned top-left inside a big available suggested
bounding box.

### Computed bounding box

This is the bounding box of the element after it has received a suggested bounding
box and applied its own layout logic. This is the bounding box in which the elements
main area will be in the scene.

### Auto-determined width and height

Some elements can compute their own size, depending on their settings. `LText`,
for example, can compute the bounding box of its text. If an object has no specific
content, like an `LAxis`, the auto-determined width or height will be `nothing`.

### Computed width and height

The computed width and height is the size that the element reports to a `GridLayout`
that it is a content element of. This can be different from the auto-size if the
object doesn't want its parent layout to know its auto-size. This is useful if
you don't want a column to shrink to the size of an `LText`, for example.

### Protrusions

These are four values that tell the `GridLayout` how much gap space is needed by
the element outside of the main element area. With an `LAxis` that would be the
title at the top, y axis at the left side and x axis at the bottom in standard
configuration.
