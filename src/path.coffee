_ = window._ or require 'underscore'

EventEmitter = window.EventEmitter or require('events').EventEmitter

attrs = {fill: '#eee', stroke: 'none'}

IDS = 0

# Represents a <path> svg element. Contains one or more `Curve.Subpath` objects
class Path extends EventEmitter
  constructor: (@svgDocument, {svgEl}={}) ->
    @id = IDS++
    @subpaths = []
    @_setupSVGObject(svgEl)

  toString: ->
    "Path #{@id} #{@toPathString()}"
  toPathString: ->
    (subpath.toPathString() for subpath in @subpaths).join(' ')

  getNodes: ->
    _.flatten(subpath.getNodes() for subpath in @subpaths, true)

  enableDragging: (callbacks) ->
    element = @svgEl
    return unless element?
    @disableDragging()
    element.draggable()
    element.dragstart = (event) -> callbacks.dragstart?(event)
    element.dragmove = (event) =>
      @update()
      callbacks.dragmove?(event)
    element.dragend = (event) =>
      @transform = null
      @translate([event.x, event.y])
      callbacks.dragend?(event)

  disableDragging: ->
    element = @svgEl
    return unless element?
    element.fixed?()
    element.dragstart = null
    element.dragmove = null
    element.dragend = null

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

  addSubpath: (subpath) ->
    @subpaths.push(subpath)
    @_bindSubpath(subpath)

    args =
      event: 'add:subpath'
      value: subpath
    @emit(args.event, this, args)
    @emit('change', this, args)
    subpath

  translate: (point) ->
    point = Point.create(point)
    for subpath in @subpaths
      subpath.translate(point)
    return

  # Call to update the model based on potentially changed node attributes
  update: (event) ->
    newTransform = @svgEl.attr('transform')
    if newTransform isnt @transform
      @transform = newTransform
      @emit 'change', this, {@transform}

  # Will render the nodes and the transform
  render: (svgEl=@svgEl) ->
    pathStr = @toPathString()
    svgEl.attr(d: pathStr) if pathStr
    svgEl.attr(transform: @transform)

  onSubpathEvent: (subpath, eventArgs) =>
    @emit eventArgs.event, this, _.extend({subpath}, eventArgs)

  onSubpathChange: (subpath, eventArgs) =>
    @render()
    @emit 'change', this, _.extend({subpath}, eventArgs)

  _createSubpath: (args) ->
    @addSubpath(new Subpath(_.extend({path: this}, args)))

  _bindSubpath: (subpath) ->
    return unless subpath
    subpath.on 'change', @onSubpathChange
    subpath.on 'close', @onSubpathEvent
    subpath.on 'insert:node', @onSubpathEvent
    subpath.on 'replace:nodes', @onSubpathEvent

  _unbindSubpath: (subpath) ->
    return unless subpath
    subpath.off 'change', @onSubpathChange
    subpath.off 'close', @onSubpathEvent
    subpath.off 'insert:node', @onSubpathEvent
    subpath.off 'replace:nodes', @onSubpathEvent

  _parseFromPathString: (pathString) ->
    return unless pathString

    parsedPath = Curve.PathParser.parsePath(pathString)
    @_createSubpath(parsedSubpath) for parsedSubpath in parsedPath.subpaths

    @currentSubpath = _.last(@subpaths)

    null

  _setupSVGObject: (@svgEl) ->
    @svgEl = @svgDocument.path().attr(attrs) unless @svgEl
    Curve.Utils.setObjectOnNode(@svgEl.node, this)
    @_parseFromPathString(@svgEl.attr('d'))

Curve.Path = Path
