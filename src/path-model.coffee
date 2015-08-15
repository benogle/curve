{Emitter, CompositeDisposable} = require 'event-kit'
Delegator = require 'delegato'

PathParser = require './path-parser'
Transform = require './transform'
Subpath = require './subpath'
Point = require './point'

IDS = 0

flatten = (array) ->
  concat = (accumulator, item) ->
    if Array.isArray(item)
      accumulator.concat(flatten(item));
    else
      accumulator.concat(item);
  array.reduce(concat, [])

# The PathModel contains the object representation of an SVG path string + SVG
# object transformations. Basically translates something like 'M0,0C20,30...Z'
# into a list of {Curve.Subpath} objects that each contains a list of
# {Curve.Node} objects. This model has no idea how to render SVG or anything
# about the DOM.
module.exports =
class PathModel
  constructor: ->
    @emitter = new Emitter
    @id = IDS++
    @subpaths = []
    @pathString = ''
    @transform = new Transform

  on: (args...) -> @emitter.on(args...)

  ###
  Section: Path Details
  ###

  getType: -> 'Path'

  getID: -> "#{@getType()}-#{@id}"

  toString: -> @getPathString()

  getSubpaths: -> @subpaths

  getNodes: ->
    nodes = (subpath.getNodes() for subpath in @subpaths)
    flatten(nodes)

  ###
  Section: Position / Size Methods
  ###

  translate: (point) ->
    point = Point.create(point)
    for subpath in @subpaths
      subpath.translate(point)
    return

  ###
  Section: Editable Attributes
  ###

  getTransform: -> @transform

  getTransformString: -> @transform.toString()

  setTransformString: (transformString) ->
    if @transform.setTransformString(transformString)
      @_emitChangeEvent()

  getPathString: -> @pathString

  setPathString: (pathString) ->
    if pathString isnt @pathString
      @_parseFromPathString(pathString)

  ###
  Section: Curent Subpath stuff

  FIXME: the currentSubpath thing will probably leave. depends on how insert
  nodes works in interface.
  ###

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

  _emitChangeEvent: (eventName) ->
    @emitter.emit("change:#{eventName}", this) if eventName
    @emitter.emit('change', this)
