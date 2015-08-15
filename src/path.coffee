{Emitter, CompositeDisposable} = require 'event-kit'
Delegator = require 'delegato'

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
  @delegatesMethods 'getID', 'getType',
    'getPathString',
    'getNodes', 'getSubpaths', 'addNode', 'insertNode', 'close',
    'translate'
    toProperty: 'model'

  constructor: (@svgDocument, {svgEl}={}) ->
    @emitter = new Emitter
    @_draggingEnabled = false
    @model = new PathModel
    @model.on 'change', @onModelChange
    @model.on 'insert:node', @_forwardEvent.bind(this, 'insert:node')
    @_setupSVGObject(svgEl)
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
    pathString = @svgEl.attr('d')
    transform = @svgEl.attr('transform')
    @model.setTransformString(transform)
    @model.setPathString(pathString)

  # Will render the nodes and the transform from the model.
  render: (svgEl=@svgEl) ->
    pathStr = @model.getPathString()
    svgEl.attr(d: pathStr) if pathStr
    svgEl.attr(transform: @model.getTransformString() or null)

  cloneElement: (svgDocument=@svgDocument) ->
    el = svgDocument.getObjectLayer().path()
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

  _forwardEvent: (eventName, args) ->
    args.path = this
    @emitter.emit(eventName, args)

  _setupSVGObject: (@svgEl) ->
    @svgEl = @svgDocument.getObjectLayer().path().attr(DefaultAttrs) unless @svgEl
    Utils.setObjectOnNode(@svgEl.node, this)
    @model.setPathString(@svgEl.attr('d'))
