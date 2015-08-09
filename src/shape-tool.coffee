{Emitter} = require 'event-kit'

Point = require './point'
Size = require './size'
Rectangle = require './rectangle'

module.exports =
class ShapeTool
  constructor: (@svgDocument, {@selectionModel}={}) ->
    @objectRoot = @svgDocument
    @emitter = new Emitter

  on: (args...) -> @emitter.on(args...)

  getType: -> @shapeType

  supportsType: (type) -> type in ['shape', 'rectangle']

  isActive: -> @active

  activate: (@shapeType) ->
    @shapeType ?= 'rectangle'
    @svgDocument.node.style.cursor = 'crosshair'
    @svgDocument.on 'mousedown', @onMouseDown
    @svgDocument.on 'mousemove', @onMouseMove
    @svgDocument.on 'mouseup', @onMouseUp
    @active = true

  deactivate: ->
    @svgDocument.node.style.cursor = null
    @svgDocument.off 'mousedown', @onMouseDown
    @svgDocument.off 'mousemove', @onMouseMove
    @svgDocument.off 'mouseup', @onMouseUp
    @active = false

  setObjectRoot: (@objectRoot) ->

  createShape: (params) ->
    if @shapeType is 'rectangle'
      new Rectangle(@objectRoot, params)
    else
      null

  onMouseDown: (event) =>
    @anchor = getCanvasPosition(@svgDocument, event)
    true

  onMouseMove: (event) =>
    return unless @anchor?
    point = getCanvasPosition(@svgDocument, event)

    if not @shape and (Math.abs(point.x - @anchor.x) >= 5 or Math.abs(point.y - @anchor.y) >= 5)
      @shape = @createShape({x: @anchor.x, y: @anchor.y, width: 0, height: 0})
      @selectionModel.setSelected(@shape)

    return unless @shape

    {size, position} = normalizePositionAndSize(@anchor, point)

    if event.shiftKey
      # constrain to 1:1 ratio when holding shift
      size = Math.min(size.width, size.height)
      size = new Size(size, size)

    @shape.setPosition(position)
    @shape.setSize(size)

  onMouseUp: (event) =>
    @anchor = null
    if @shape?
      @shape = null
    else
      @emitter.emit('cancel')

normalizePositionAndSize = (anchor, point) ->
  topLeft = new Point(Math.min(anchor.x, point.x), Math.min(anchor.y, point.y))
  bottomRight = new Point(Math.max(anchor.x, point.x), Math.max(anchor.y, point.y))
  diff = bottomRight.subtract(topLeft)
  {position: topLeft, size: new Size(diff.x, diff.y)}

getCanvasPosition = (svgDocument, event) ->
  x = event.pageX - svgDocument.node.offsetLeft
  y = event.pageY - svgDocument.node.offsetTop
  new Point(x, y)
