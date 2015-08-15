{Emitter} = require 'event-kit'
ObjectAssign = require 'object-assign'
Delegator = require 'delegato'

Utils = require './utils'
Draggable = require './draggable-mixin'

RectangleModel = require './rectangle-model'

DefaultAttrs = {x: 0, y: 0, width: 10, height: 10, fill: '#eee', stroke: 'none'}
IDS = 0

# Represents a <rect> svg element. Handles interacting with the element, and
# rendering from the {RectangleModel}.
module.exports =
class Rectangle
  Draggable.includeInto(this)
  Delegator.includeInto(this)

  @delegatesMethods 'on', toProperty: 'emitter'
  @delegatesMethods 'get', 'set', 'translate',
    toProperty: 'model'

  constructor: (@svgDocument, options={}) ->
    @emitter = new Emitter
    @model = new RectangleModel
    @_setupSVGObject(options)
    @model.on 'change', @onModelChange
    @svgDocument.registerObject(this)

  ###
  Section: Public Methods
  ###

  getType: -> 'Rectangle'

  getID: -> "#{@getType()}-#{@id}"

  toString: -> @model.toString()

  remove: ->
    @svgEl.remove()
    @emitter.emit('remove', object: this)

  # Call when the XML attributes change without the model knowing. Will update
  # the model with the new attributes.
  updateFromAttributes: ->
    x = @svgEl.attr('x')
    y = @svgEl.attr('y')
    width = @svgEl.attr('width')
    height = @svgEl.attr('height')
    transform = @svgEl.attr('transform')

    @model.set
      position: [x, y]
      size: [width, height]
      transform: transform

  # Will render the nodes and the transform from the model.
  render: (svgEl=@svgEl) ->
    position = @model.get('position')
    size = @model.get('size')
    svgEl.attr(x: position.x)
    svgEl.attr(y: position.y)
    svgEl.attr(width: size.width)
    svgEl.attr(height: size.height)
    svgEl.attr(transform: @model.get('transform') or null)

  cloneElement: (svgDocument=@svgDocument) ->
    el = svgDocument.getObjectLayer().rect()
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
    @svgEl = @svgDocument.getObjectLayer().rect().attr(ObjectAssign({}, DefaultAttrs, options)) unless @svgEl
    Utils.setObjectOnNode(@svgEl.node, this)
    @updateFromAttributes()
