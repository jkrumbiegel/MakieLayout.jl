# MakieLayout.jl

The package is quite new and therefore still in constant flux.
Check out the current [documentation here](https://jkrumbiegel.github.io/MakieLayout.jl/dev/)!

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://jkrumbiegel.github.io/MakieLayout.jl/dev/)
[![Build Status](https://travis-ci.com/jkrumbiegel/MakieLayout.jl.svg?branch=master)](https://travis-ci.com/jkrumbiegel/MakieLayout.jl)
[![Codecov](https://codecov.io/gh/jkrumbiegel/Animations.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jkrumbiegel/MakieLayout.jl)

## Purpose

`MakieLayout.jl` brings grid layouts, a new 2D axis, and widgets like sliders and buttons
that behave well in a layout to `Makie.jl`. You can create any 2D layout you want with
the flexible combination of these features:

- fixed, relative, aspect preserving or automatic row and column sizes
- fixed or relative size gaps
- elements spanning multiple rows and columns
- automatically determine the size of objects like text so no space is wasted
- automatic alignment along "important edges" like axis spines

Most layout parameters are instantly adjustable using Observables, as in Makie.jl.
Also, the layout automatically readjusts if you change visual attributes of your
content elements.

![layout demo](https://raw.githubusercontent.com/jkrumbiegel/MakieLayout.jl/gh-pages/additional_media/layoutdemo.gif)
