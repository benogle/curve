_ = window._ or require 'underscore'

#
class Size
  @create: (width, height) ->
    return width if width instanceof Size
    if Array.isArray(width)
      new Size(width[0], width[1])
    else
      new Size(width, height)

  constructor: (width, height) ->
    @set(width, height)

  set: (@width, @height) ->
    [@width, @height] = @width if _.isArray(@width)

  toArray: ->
    [@width, @height]

  equals: (other) ->
    other = Size.create(other)
    other.width == @width and other.height == @height

  toString: ->
    "(#{@width}, #{@height})"

Curve.Size = Size
