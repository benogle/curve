_ = window._ or require 'underscore'

EventEmitter = window.EventEmitter or require('events').EventEmitter
DefaultAttrs = {x: 0, y: 0, width: 10, height: 10, fill: '#eee', stroke: 'none'}
IDS = 0

class RectangleModel extends EventEmitter
  position: null
  size: null
  transform: null

  constructor: ->
    @id = IDS++
    @transform = new Curve.Transform

  ###
  Section: Public Methods
  ###

  getTransform: -> @transform

  getTransformString: -> @transform.toString()

  setTransformString: (transformString) ->
    if @transform.setTransformString(transformString)
      @_emitChangeEvent()

  getPosition: -> @position

  setPosition: (x, y) ->
    @position = Point.create(x, y)
    @_emitChangeEvent()

  getSize: -> @size

  setSize: (width, height) ->
    @size = Size.create(width, height)
    @_emitChangeEvent()

  toString: -> "{Rect #{@id}: #{@position} #{@size}"

  translate: (point) ->
    point = Point.create(point)
    @setPosition(@position.add(point))
    @_emitChangeEvent()

  ###
  Section: Private Methods
  ###

  _emitChangeEvent: ->
    @emit 'change', this




# Represents a <rect> svg element. Handles interacting with the element, and
# rendering from the {RectangleModel}.
class Rectangle extends EventEmitter
  constructor: (@svgDocument, {svgEl}={}) ->
    @model = new RectangleModel
    @_setupSVGObject(svgEl)
    @model.on 'change', @onModelChange

  ###
  Section: Public Methods
  ###

  getType: -> 'Rectangle'

  toString: -> @model.toString()

  # Allows for user dragging on the screen
  enableDragging: (callbacks) ->
    element = @svgEl
    return unless element?
    @disableDragging()
    element.draggable()
    element.dragstart = (event) -> callbacks?.dragstart?(event)
    element.dragmove = (event) =>
      @updateFromAttributes()
      callbacks?.dragmove?(event)
    element.dragend = (event) =>
      @model.setTransformString(null)
      @model.translate([event.x, event.y])
      callbacks?.dragend?(event)

  disableDragging: ->
    element = @svgEl
    return unless element?
    element.fixed?()
    element.dragstart = null
    element.dragmove = null
    element.dragend = null

  # Call when the XML attributes change without the model knowing. Will update
  # the model with the new attributes.
  updateFromAttributes: ->
    x = @svgEl.attr('x')
    y = @svgEl.attr('y')
    width = @svgEl.attr('width')
    height = @svgEl.attr('height')
    transform = @svgEl.attr('transform')
    @model.setPosition(x, y)
    @model.setSize(width, height)
    @model.setTransformString(transform)

  # Will render the nodes and the transform from the model.
  render: (svgEl=@svgEl) ->
    position = @model.getPosition()
    size = @model.getSize()
    svgEl.attr(x: position.x)
    svgEl.attr(y: position.y)
    svgEl.attr(width: size.width)
    svgEl.attr(height: size.height)
    svgEl.attr(transform: @model.getTransformString() or null)

  cloneElement: (svgDocument=@svgDocument) ->
    el = svgDocument.rect()
    @render(el)
    el

  ###
  Section: Event Handlers
  ###

  onModelChange: =>
    @render()
    @emit 'change', this

  ###
  Section: Private Methods
  ###

  _setupSVGObject: (@svgEl) ->
    @svgEl = @svgDocument.rect().attr(DefaultAttrs) unless @svgEl
    Curve.Utils.setObjectOnNode(@svgEl.node, this)
    @updateFromAttributes()

Curve.Rectangle = Rectangle
