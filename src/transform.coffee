Point = require "./point"

TranslateRegex = /translate\(([-0-9]+)[ ]+([-0-9]+)\)/

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
    @translation = null
    @transformString = ''

  setTransformString: (transformString='') ->
    if @transformString is transformString
      false
    else
      @transformString = transformString
      translation = TranslateRegex.exec(transformString)
      if translation?
        x = parseInt(translation[1])
        y = parseInt(translation[2])
        @translation = new Point(x, y)
      else
        @translation = null
      true

  toString: ->
    @transformString

  transformPoint: (point) ->
    point = Point.create(point)
    point = point.add(@translation) if @translation
    point
