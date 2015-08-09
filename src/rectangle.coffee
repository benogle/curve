{Emitter} = require 'event-kit'
Transform = require './transform'
Utils = require './utils'
Point = require './point'
Size = require './size'
Draggable = require './draggable-mixin'

ObjectAssign = require 'object-assign'

DefaultAttrs = {x: 0, y: 0, width: 10, height: 10, fill: '#eee', stroke: 'none'}
IDS = 0

class RectangleModel
  position: null
  size: null
  transform: null

  constructor: ->
    @emitter = new Emitter
    @id = IDS++
    @transform = new Transform

  on: (args...) -> @emitter.on(args...)

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
    @emitter.emit 'change', this




# Represents a <rect> svg element. Handles interacting with the element, and
# rendering from the {RectangleModel}.
module.exports =
class Rectangle
  Draggable.includeInto(this)

  constructor: (@svgDocument, options={}) ->
    @emitter = new Emitter
    @model = new RectangleModel
    @_setupSVGObject(options)
    @model.on 'change', @onModelChange

  on: (args...) -> @emitter.on(args...)

  ###
  Section: Public Methods
  ###

  getType: -> 'Rectangle'

  toString: -> @model.toString()

  getPosition: -> @model.getPosition()

  translate: (point) -> @model.translate(point)

  # Call when the XML attributes change without the model knowing. Will update
  # the model with the new attributes.
  updateFromAttributes: ->
    x = @svgEl.attr('x')
    y = @svgEl.attr('y')
    @model.setPosition(x, y)

    width = @svgEl.attr('width')
    height = @svgEl.attr('height')
    @model.setSize(width, height)

    transform = @svgEl.attr('transform')
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
    @emitter.emit 'change', this

  ###
  Section: Private Methods
  ###

  _setupSVGObject: (options) ->
    {@svgEl} = options
    @svgEl = @svgDocument.rect().attr(ObjectAssign({}, DefaultAttrs, options)) unless @svgEl
    Utils.setObjectOnNode(@svgEl.node, this)
    @updateFromAttributes()
