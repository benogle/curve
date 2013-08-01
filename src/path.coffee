_ = window._ or require 'underscore'

EventEmitter = window.EventEmitter or require('events').EventEmitter

attrs = {fill: '#eee', stroke: 'none'}

###
  TODO
  * experiment with loading a file then editing it
  * change path -> svgEl in cases where it makes sense
  * removing nodes with keyboard
  * move entire object
  * select/deselect objects
  * make new objects
  * replacing path array updates the interface

  Large
  * how to deal with events and tools and things?
    * like NodeEditor is dragging something, the pointer tool should be deactivated.
    * a tool manager? can push/pop tools?
  * probably need a doc object
    * Can pass it to everything that needs to use svg
    * would have access to the tools n junk
  * proper z-index of elements
    * group for doc at the bottom
    * group for selection
    * group for tool nodes
###

IDS = 0
#
class Curve.Path extends EventEmitter
  constructor: (svgEl) ->
    @path = null
    @nodes = []
    @isClosed = false

    @_setupSVGObject(svgEl)

    @id = IDS++

  toString: ->
    "Path #{@id}"

  addNode: (node) ->
    @insertNode(node, @nodes.length)

  insertNode: (node, index) ->
    @_bindNode(node)
    @nodes.splice(index, 0, node)
    @render()

    args =
      event: 'insert:node'
      index: index
      value: node
    @emit('insert:node', this, args)
    @emit('change', this, args)

  close: ->
    @isClosed = true
    @render()

    args = event: 'close'
    @emit('close', this, args)
    @emit('change', this, args)

  render: (svgEl=@svgEl) ->
    pathStr = @toPathString()
    svgEl.attr(d: pathStr) if pathStr

  toPathString: ->
    path = ''
    lastPoint = null

    makeCurve = (fromNode, toNode) ->
      curve = []
      curve = curve.concat(fromNode.getAbsoluteHandleOut().toArray())
      curve = curve.concat(toNode.getAbsoluteHandleIn().toArray())
      curve = curve.concat(toNode.point.toArray())
      'C' + curve.join(',')

    closePath = (firstNode, lastNode)->
      closingPath = ''
      closingPath += makeCurve(lastNode, firstNode) if lastNode.handleOut or firstNode.handleIn
      closingPath += 'Z'

    for node in @nodes
      if node.isMoveNode or !path
        firstNode = node
        path += 'M' + node.point.toArray().join(',')
      else
        path += makeCurve(lastNode, node)

      lastNode = node
      path += closePath(firstNode, lastNode) if node.isCloseNode

    if @isClosed and path[path.length - 1] != 'Z'
      closePath(firstNode, @nodes[@nodes.length-1])

    path

  onNodeChange: (node, eventArgs) =>
    @render()

    index = @_findNodeIndex(node)
    @emit 'change', this, _.extend({index}, eventArgs)

  _parseFromPathString: (pathString) ->
    return unless pathString

    parsedPath = Curve.PathParser.parsePath(pathString)
    @nodes = parsedPath.nodes
    @_bindNode(node) for node in @nodes

    @close() if parsedPath.closed

  _bindNode: (node) ->
    node.on 'change', @onNodeChange

  _findNodeIndex: (node) ->
    for i in [0...@nodes.length]
      return i if @nodes[i] == node
    -1

  _setupSVGObject: (@svgEl) ->
    @svgEl = svg.path().attr(attrs) unless @svgEl
    Curve.Utils.setObjectOnNode(@svgEl.node, this)
    @_parseFromPathString(@svgEl.attr('d'))
