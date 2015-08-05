module.exports =
class Point
  @create: (x, y) ->
    return x if x instanceof Point
    if x?.x? and x?.y?
      new Point(x.x, x.y)
    else if Array.isArray(x)
      new Point(x[0], x[1])
    else
      new Point(x, y)

  constructor: (x, y) ->
    @set(x, y)

  set: (@x, @y) ->
    [@x, @y] = @x if Array.isArray(@x)

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

  toString: ->
    "(#{@x}, #{@y})"
