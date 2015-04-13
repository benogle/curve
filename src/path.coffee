_ = window._ or require 'underscore'

EventEmitter = window.EventEmitter or require('events').EventEmitter
DefaultAttrs = {fill: '#eee', stroke: 'none'}
IDS = 0

# The PathModel contains the object representation of an SVG path string + SVG
# object transformations. Basically translates something like 'M0,0C20,30...Z'
# into a list of {Curve.Subpath} objects that each contains a list of
# {Curve.Node} objects. This model has no idea how to render SVG or anything
# about the DOM.
class PathModel extends EventEmitter
  constructor: ->
    @subpaths = []
    @pathString = ''
    @transform = new Curve.Transform

  ###
  Section: Public Methods
  ###

  getNodes: ->
    _.flatten(subpath.getNodes() for subpath in @subpaths, true)

  getTransform: -> @transform

  getTransformString: -> @transform.toString()

  setTransformString: (transformString) ->
    if @transform.setTransformString(transformString)
      @_emitChangeEvent()

  getPathString: -> @pathString

  setPathString: (pathString) ->
    if pathString isnt @pathString
      @_parseFromPathString(pathString)

  toString: -> @getPathString()

  translate: (point) ->
    point = Point.create(point)
    for subpath in @subpaths
      subpath.translate(point)
    return

  # FIXME: the currentSubpath thing will probably leave. depends on how insert
  # nodes works in interface.
  addNode: (node) ->
    @_addCurrentSubpathIfNotPresent()
    @currentSubpath.addNode(node)
  insertNode: (node, index) ->
    @_addCurrentSubpathIfNotPresent()
    @currentSubpath.insertNode(node, index)
  close: ->
    @_addCurrentSubpathIfNotPresent()
    @currentSubpath.close()
  _addCurrentSubpathIfNotPresent: ->
    @currentSubpath = @_createSubpath() unless @currentSubpath
  # End currentSubpath stuff

  ###
  Section: Event Handlers
  ###

  onSubpathChange: (subpath, eventArgs) =>
    @_updatePathString()
    @_emitChangeEvent()

  ###
  Section: Private Methods
  ###

  _createSubpath: (args={}) ->
    args.path = this
    @_addSubpath(new Subpath(args))

  _addSubpath: (subpath) ->
    @subpaths.push(subpath)
    @_bindSubpath(subpath)
    @_updatePathString()
    subpath

  _bindSubpath: (subpath) ->
    return unless subpath
    subpath.on 'change', @onSubpathChange
    subpath.on 'insert:node', @_forwardEvent.bind(this, 'insert:node')

  _unbindSubpath: (subpath) ->
    return unless subpath
    subpath.off() # scary!

  _removeAllSubpaths: ->
    for subpath in @subpaths
      @_unbindSubpath(subpath)
    @subpaths = []

  _updatePathString: ->
    oldPathString = @pathString
    @pathString = (subpath.toPathString() for subpath in @subpaths).join(' ')
    @_emitChangeEvent() if oldPathString isnt @pathString

  _parseFromPathString: (pathString) ->
    return unless pathString
    return if pathString is @pathString
    @_removeAllSubpaths()
    parsedPath = Curve.PathParser.parsePath(pathString)
    @_createSubpath(parsedSubpath) for parsedSubpath in parsedPath.subpaths
    @currentSubpath = _.last(@subpaths)
    @_updatePathString()
    null

  _forwardEvent: (eventName, eventObject, args) ->
    @emit(eventName, this, args)

  _emitChangeEvent: ->
    @emit 'change', this




# Represents a <path> svg element. Handles interacting with the element, and
# rendering from the {PathModel}.
class Path extends EventEmitter
  constructor: (@svgDocument, {svgEl}={}) ->
    @id = IDS++
    @model = new PathModel
    @model.on 'change', @onModelChange
    @model.on 'insert:node', @_forwardEvent.bind(this, 'insert:node')
    @_setupSVGObject(svgEl)

  ###
  Section: Public Methods
  ###

  toString: ->
    "Path #{@id} #{@model.toString()}"

  getPathString: -> @model.getPathString()

  getNodes: -> @model.getNodes()

  getSubpaths: -> @model.subpaths

  addNode: (node) -> @model.addNode(node)

  insertNode: (node, index) -> @model.insertNode(node, index)

  close: -> @model.close()

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
    pathString = @svgEl.attr('d')
    transform = @svgEl.attr('transform')
    @model.setTransformString(transform)
    @model.setPathString(pathString)

  # Will render the nodes and the transform from the model.
  render: (svgEl=@svgEl) ->
    pathStr = @model.getPathString()
    svgEl.attr(d: pathStr) if pathStr
    svgEl.attr(transform: @model.getTransformString() or null)

  ###
  Section: Event Handlers
  ###

  onModelChange: =>
    @render()
    @emit 'change', this

  ###
  Section: Private Methods
  ###

  _forwardEvent: (eventName, eventObject, args) ->
    args.path = this
    @emit(eventName, this, args)

  _setupSVGObject: (@svgEl) ->
    @svgEl = @svgDocument.path().attr(DefaultAttrs) unless @svgEl
    Curve.Utils.setObjectOnNode(@svgEl.node, this)
    @model.setPathString(@svgEl.attr('d'))

Curve.Path = Path
