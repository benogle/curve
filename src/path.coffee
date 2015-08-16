{Emitter, CompositeDisposable} = require 'event-kit'
Delegator = require 'delegato'
ObjectAssign = require 'object-assign'

Utils = require './utils'
Point = require './point'
Draggable = require './draggable-mixin'
PathModel = require './path-model'

DefaultAttrs = {fill: '#eee', stroke: 'none'}

# Represents a <path> svg element. Handles interacting with the element, and
# rendering from the {PathModel}.
module.exports =
class Path
  Draggable.includeInto(this)
  Delegator.includeInto(this)

  @delegatesMethods 'on', toProperty: 'emitter'
  @delegatesMethods 'get', 'set', 'getID', 'getType',
    'getNodes', 'getSubpaths', 'addNode', 'insertNode', 'removeNode', 'createSubpath', 
    'close', 'isClosed'
    'translate'
    toProperty: 'model'

  constructor: (@svgDocument, options={}) ->
    @emitter = new Emitter
    @_draggingEnabled = false
    @model = new PathModel
    @model.on 'change', @onModelChange
    @model.on 'insert:node', @_forwardEvent.bind(this, 'insert:node')
    @_setupSVGObject(options)
    @svgDocument.registerObject(this)

  ###
  Section: Public Methods
  ###

  toString: ->
    "Path #{@id} #{@model.toString()}"

  getModel: -> @model

  getPosition: ->
    new Point(@svgEl.x(), @svgEl.y())

  remove: ->
    @svgEl.remove()
    @emitter.emit('remove', object: this)

  # Call when the XML attributes change without the model knowing. Will update
  # the model with the new attributes.
  updateFromAttributes: ->
    path = @svgEl.attr('d')
    transform = @svgEl.attr('transform')
    fill = @svgEl.attr('fill')
    @model.set({transform, path, fill})

  # Will render the nodes and the transform from the model.
  render: (svgEl=@svgEl) ->
    pathStr = @model.get('path')
    fill = @model.get('fill')
    svgEl.attr(d: pathStr) if pathStr
    svgEl.attr(fill: @model.get('fill')) if fill and fill isnt '#000000'
    svgEl.attr
      transform: @model.get('transform') or null

  cloneElement: (svgDocument=@svgDocument) ->
    el = svgDocument.getObjectLayer().path()
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

  _forwardEvent: (eventName, args) ->
    args.object = this
    @emitter.emit(eventName, args)

  _setupSVGObject: (options) ->
    {@svgEl} = options
    @svgEl = @svgDocument.getObjectLayer().path().attr(ObjectAssign({}, DefaultAttrs, options)) unless @svgEl
    Utils.setObjectOnNode(@svgEl.node, this)
    @updateFromAttributes()
