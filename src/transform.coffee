SVG = require '../vendor/svg'
Point = require "./point"

# Transform class parses the string from an SVG transform attribute, and running
# points through the parsed transformation.
#
# TODO:
#
# * Add support for all other transformations. Currently this only supports
#   translations because I didnt need anything else.
#
module.exports =
class Transform
  constructor: ->
    @matrix = null
    @transformString = ''

  setTransformString: (transformString='') ->
    if @transformString is transformString
      false
    else
      @transformString = transformString
      transform = SVG.parse.transform(transformString)

      @matrix = null
      if transform
        @matrix = SVG.parser.draw.node.createSVGMatrix()
        if transform.x?
          @matrix = @matrix.translate(transform.x, transform.y)
        else if transform.a?
          for k, v of transform
            @matrix[k] = transform[k]
        else
          @matrix = null

      true

  toString: ->
    @transformString

  transformPoint: (point) ->
    point = Point.create(point)
    if @matrix
      svgPoint = SVG.parser.draw.node.createSVGPoint()
      svgPoint.x = point.x
      svgPoint.y = point.y
      svgPoint = svgPoint.matrixTransform(@matrix)
      Point.create(svgPoint.x, svgPoint.y)
    else
      point
