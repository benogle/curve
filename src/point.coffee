
#
class Point
  @create: (x, y) ->
    return x if x instanceof Point
    new Point(x, y)

  constructor: (x, y) ->
    @set(x, y)

  set: (@x, @y) ->
    [@x, @y] = @x if _.isArray(@x)

  add: (other) ->
    other = Point.create(other)
    new Point(@x + other.x, @y + other.y)

  subtract: (other) ->
    other = Point.create(other)
    new Point(@x - other.x, @y - other.y)

  toArray: ->
    [@x, @y]

  equals: (other) ->
    other = Point.create(other)
    other.x == @x and other.y == @y

_.extend(window.Curve, {Point})
