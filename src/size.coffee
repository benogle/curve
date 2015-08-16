Point = require './point'

#
module.exports =
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
    [@width, @height] = @width if Array.isArray(@width)

  add: (width, height) ->
    if width instanceof Point or (width.x? and width.y?)
      point = width
      new Size(@width + point.x, @height + point.y)
    else
      other = Size.create(width, height)
      new Size(@width + other.width, @height + other.height)

  toArray: ->
    [@width, @height]

  equals: (other) ->
    other = Size.create(other)
    other.width == @width and other.height == @height

  toString: ->
    "(#{@width}, #{@height})"
