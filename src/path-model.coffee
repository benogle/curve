{Emitter, CompositeDisposable} = require 'event-kit'
Delegator = require 'delegato'

PathParser = require './path-parser'
Transform = require './transform'
Subpath = require './subpath'
Point = require './point'
Model = require './model'

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
class PathModel extends Model

  constructor: ->
    super(['transform', 'path', 'fill'])
    @id = IDS++
    @subpaths = []
    @transform = new Transform

    @addFilter 'path', (value) => @_parseFromPathString(value)

    @subscriptions = new CompositeDisposable
    @subscriptions.add @on 'change:transform', ({value}) => @transform.setTransformString(value)

  destroy: ->
    @subscriptions.dispose()

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

  getTransform: -> @transform

  ###
  Section: Current Subpath stuff

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
    @set({path: @_pathToString()}, filter: false)

  _pathToString: ->
    (subpath.toPathString() for subpath in @subpaths).join(' ')

  _parseFromPathString: (pathString) ->
    return unless pathString
    return if pathString is @pathString
    @_removeAllSubpaths()
    parsedPath = PathParser.parsePath(pathString)
    @_createSubpath(parsedSubpath) for parsedSubpath in parsedPath.subpaths
    @currentSubpath = @subpaths[@subpaths.length - 1]
    @_pathToString()

  _forwardEvent: (eventName, args) ->
    @emitter.emit(eventName, args)
