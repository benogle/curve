{Emitter} = require 'event-kit'
ObjectAssign = require 'object-assign'
Delegator = require 'delegato'

Utils = require './utils'
Draggable = require './draggable-mixin'

EllipseModel = require './ellipse-model'

DefaultAttrs = {cx: 5, cy: 5, rx: 5, ry: 5, fill: '#eee', stroke: 'none'}
IDS = 0

# Represents a <ellipse> svg element. Handles interacting with the element, and
# rendering from the {EllipseModel}.
module.exports =
class Ellipse
  Draggable.includeInto(this)
  Delegator.includeInto(this)

  @delegatesMethods 'on', toProperty: 'emitter'
  @delegatesMethods 'get', 'set', 'getID', 'getType', 'toString',
    'translate',
    toProperty: 'model'

  constructor: (@svgDocument, options={}) ->
    @emitter = new Emitter
    @model = new EllipseModel
    @_setupSVGObject(options)
    @model.on 'change', @onModelChange
    @svgDocument.registerObject(this)

  ###
  Section: Public Methods
  ###

  remove: ->
    @svgEl.remove()
    @emitter.emit('remove', object: this)

  # Call when the XML attributes change without the model knowing. Will update
  # the model with the new attributes.
  updateFromAttributes: ->
    r = @svgEl.attr('r')
    if r
      rx = ry = r
    else
      rx = @svgEl.attr('rx')
      ry = @svgEl.attr('ry')
    x = @svgEl.attr('cx') - rx
    y = @svgEl.attr('cy') - ry

    width = rx * 2
    height = ry * 2
    transform = @svgEl.attr('transform')
    fill = @svgEl.attr('fill')

    @model.set({position: [x, y], size: [width, height], transform, fill})

  # Will render data from the model
  render: (svgEl=@svgEl) ->
    position = @model.get('position')
    size = @model.get('size')
    attrs = {x: position.x, y: position.y, width: size.width, height: size.height}
    svgEl.attr ObjectAssign {
      transform: @model.get('transform') or null
      fill: @model.get('fill') or null
    }, @_convertPositionAndSizeToCenter(attrs)

  cloneElement: (svgDocument=@svgDocument) ->
    el = svgDocument.getObjectLayer().ellipse()
    @render(el)
    el

  ###
  Section: Event Handlers
  ###

  onModelChange: (args) =>
    @render()
    args.object = this
    @emitter.emit 'change', args

  ###
  Section: Private Methods
  ###

  _convertPositionAndSizeToCenter: (attrs) ->
    {x, y, width, height} = attrs
    return {} unless x? and y? and width? and height?

    rx = width / 2
    ry = height / 2
    cx = x + rx
    cy = y + ry

    {rx, ry, cx, cy}

  _setupSVGObject: (options) ->
    {@svgEl} = options
    unless @svgEl
      attrs = ObjectAssign({}, DefaultAttrs, options, @_convertPositionAndSizeToCenter(options))
      delete attrs.x
      delete attrs.y
      delete attrs.width
      delete attrs.height
      @svgEl = @svgDocument.getObjectLayer().ellipse().attr(attrs)
    Utils.setObjectOnNode(@svgEl.node, this)
    @updateFromAttributes()
