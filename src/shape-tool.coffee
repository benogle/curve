{Emitter} = require 'event-kit'

Point = require './point'
Size = require './size'
Ellipse = require './ellipse'
Rectangle = require './rectangle'
{getCanvasPosition, normalizePositionAndSize} = require './utils'

module.exports =
class ShapeTool
  constructor: (@svgDocument) ->
    @emitter = new Emitter
    @selectionModel = @svgDocument.getSelectionModel()

  on: (args...) -> @emitter.on(args...)

  getType: -> @shapeType

  supportsType: (type) -> type in ['shape', 'rectangle', 'ellipse']

  isActive: -> @active

  activate: (@shapeType) ->
    @shapeType ?= 'rectangle'
    svg = @svgDocument.getSVGRoot()
    svg.node.style.cursor = 'crosshair'
    svg.on 'mousedown', @onMouseDown
    svg.on 'mousemove', @onMouseMove
    svg.on 'mouseup', @onMouseUp
    @active = true

  deactivate: ->
    svg = @svgDocument.getSVGRoot()
    svg.node.style.cursor = null
    svg.off 'mousedown', @onMouseDown
    svg.off 'mousemove', @onMouseMove
    svg.off 'mouseup', @onMouseUp
    @active = false

  createShape: (params) ->
    if @shapeType is 'rectangle'
      new Rectangle(@svgDocument, params)
    else if @shapeType is 'ellipse'
      new Ellipse(@svgDocument, params)
    else
      null

  onMouseDown: (event) =>
    @anchor = getCanvasPosition(@svgDocument.getSVGRoot(), event)
    true

  onMouseMove: (event) =>
    return unless @anchor?
    point = getCanvasPosition(@svgDocument.getSVGRoot(), event)

    if not @shape and (Math.abs(point.x - @anchor.x) >= 5 or Math.abs(point.y - @anchor.y) >= 5)
      @shape = @createShape({x: @anchor.x, y: @anchor.y, width: 0, height: 0})
      @selectionModel.setSelected(@shape)

    return unless @shape

    {size, position} = normalizePositionAndSize(@anchor, point)

    if event.shiftKey
      # constrain to 1:1 ratio when holding shift
      size = Math.min(size.width, size.height)
      size = new Size(size, size)

    @shape.set({position, size})

  onMouseUp: (event) =>
    @anchor = null
    if @shape?
      @shape = null
    else
      @emitter.emit('cancel')
