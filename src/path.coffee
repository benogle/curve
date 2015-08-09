{Emitter, CompositeDisposable} = require 'event-kit'

Utils = require './utils'
PathParser = require './path-parser'
Transform = require './transform'
Subpath = require './subpath'
Point = require './point'
Draggable = require './draggable-mixin'

DefaultAttrs = {fill: '#eee', stroke: 'none'}
IDS = 0

# The PathModel contains the object representation of an SVG path string + SVG
# object transformations. Basically translates something like 'M0,0C20,30...Z'
# into a list of {Curve.Subpath} objects that each contains a list of
# {Curve.Node} objects. This model has no idea how to render SVG or anything
# about the DOM.
class PathModel
  constructor: ->
    @emitter = new Emitter
    @subpaths = []
    @pathString = ''
    @transform = new Transform

  on: (args...) -> @emitter.on(args...)

  ###
  Section: Public Methods
  ###

  getNodes: ->
    nodes = (subpath.getNodes() for subpath in @subpaths)
    flatten(nodes)

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
    @subpathSubscriptions ?= new CompositeDisposable
    @subpathSubscriptions.add subpath.on('change', @onSubpathChange)
    @subpathSubscriptions.add subpath.on('insert:node', @_forwardEvent.bind(this, 'insert:node'))

  _unbindSubpath: (subpath) ->
    return unless subpath
    subpath.removeAllListeners() # scary!

  _removeAllSubpaths: ->
    @subpathSubscriptions?.dispose()
    @subpathSubscriptions = null
    @subpaths = []

  _updatePathString: ->
    oldPathString = @pathString
    @pathString = (subpath.toPathString() for subpath in @subpaths).join(' ')
    @_emitChangeEvent() if oldPathString isnt @pathString

  _parseFromPathString: (pathString) ->
    return unless pathString
    return if pathString is @pathString
    @_removeAllSubpaths()
    parsedPath = PathParser.parsePath(pathString)
    @_createSubpath(parsedSubpath) for parsedSubpath in parsedPath.subpaths
    @currentSubpath = @subpaths[@subpaths.length - 1]
    @_updatePathString()
    null

  _forwardEvent: (eventName, args) ->
    @emitter.emit(eventName, args)

  _emitChangeEvent: ->
    @emitter.emit 'change', this




# Represents a <path> svg element. Handles interacting with the element, and
# rendering from the {PathModel}.
module.exports =
class Path
  Draggable.includeInto(this)

  constructor: (@svgDocument, {svgEl}={}) ->
    @emitter = new Emitter
    @_draggingEnabled = false
    @id = IDS++
    @model = new PathModel
    @model.on 'change', @onModelChange
    @model.on 'insert:node', @_forwardEvent.bind(this, 'insert:node')
    @_setupSVGObject(svgEl)

  on: (args...) -> @emitter.on(args...)

  ###
  Section: Public Methods
  ###

  getType: -> 'Path'

  toString: ->
    "Path #{@id} #{@model.toString()}"

  getPathString: -> @model.getPathString()

  getNodes: -> @model.getNodes()

  getSubpaths: -> @model.subpaths

  addNode: (node) -> @model.addNode(node)

  insertNode: (node, index) -> @model.insertNode(node, index)

  close: -> @model.close()

  translate: (delta) -> @model.translate(delta)

  getPosition: ->
    new Point(@svgEl.x(), @svgEl.y())

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

flatten = (array) ->
  concat = (accumulator, item) ->
    if Array.isArray(item)
      accumulator.concat(flatten(item));
    else
      accumulator.concat(item);
  array.reduce(concat, [])
