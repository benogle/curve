SVG = require '../../vendor/svg.js'

#
class SVG.Circle extends SVG.Shape
  constructor: ->
    super(SVG.create('circle'))

  cx: (x) ->
    if x == null then this.attr('cx') else @attr('cx', new SVG.Number(x).divide(this.trans.scaleX))

  cy: (y) ->
    if y == null then this.attr('cy') else @attr('cy', new SVG.Number(y).divide(this.trans.scaleY))

  radius: (rad) ->
    @attr(r: new SVG.Number(rad))


SVG.extend SVG.Container,
  circle: (radius) ->
    return this.put(new SVG.Circle).radius(radius).move(0, 0)
