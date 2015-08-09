Point = require './point'
Size = require './size'
Rectangle = require './rectangle'

module.exports =
class PointerTool
  constructor: (@svgDocument, {@selectionModel, @selectionView, @toolLayer}={}) ->

  activate: ->
    @svgDocument.on 'mousedown', @onMouseDown
    @svgDocument.on 'mousemove', @onMouseMove
    @svgDocument.on 'mouseup', @onMouseUp

  deactivate: ->
    @svgDocument.off 'mousedown', @onMouseDown
    @svgDocument.off 'mousemove', @onMouseMove
    @svgDocument.off 'mouseup', @onMouseUp

  onMouseDown: (event) =>
    @anchor = getCanvasPosition(@svgDocument, event)
    @rectangle = new Rectangle(@svgDocument, {x: @anchor.x, y: @anchor.y, width: 0, height: 0})
    @selectionModel.setSelected(@rectangle)
    true

  onMouseMove: (event) =>
    return unless @rectangle?
    point = getCanvasPosition(@svgDocument, event)
    {size, position} = getPositivePositionAndSize(@anchor, point)

    @rectangle.setPosition(position)
    @rectangle.setSize(size)

  onMouseUp: (event) =>
    @anchor = null
    @rectangle = null


getPositivePositionAndSize = (anchor, point) ->
  topLeft = new Point(Math.min(anchor.x, point.x), Math.min(anchor.y, point.y))
  bottomRight = new Point(Math.max(anchor.x, point.x), Math.max(anchor.y, point.y))
  diff = bottomRight.subtract(topLeft)
  {position: topLeft, size: new Size(diff.x, diff.y)}

getCanvasPosition = (svgDocument, event) ->
  x = event.pageX - svgDocument.node.offsetLeft
  y = event.pageY - svgDocument.node.offsetTop
  new Point(x, y)
