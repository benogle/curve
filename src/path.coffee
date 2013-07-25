attrs = {fill: '#eee', stroke: 'none'}
utils = window.Curve

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
class Path extends EventEmitter
  constructor: () ->
    @path = null
    @nodes = []
    @isClosed = false
    @path = @_createSVGObject()

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

  render: (path=@path) ->
    pathStr = @toPathString()
    path.attr(d: pathStr) if pathStr

  toPathString: ->
    path = ''
    lastPoint = null

    makeCurve = (fromNode, toNode) ->
      curve = []
      curve = curve.concat(fromNode.getAbsoluteHandleOut().toArray())
      curve = curve.concat(toNode.getAbsoluteHandleIn().toArray())
      curve = curve.concat(toNode.point.toArray())
      'C' + curve.join(',')

    for node in @nodes
      if path
        path += makeCurve(lastNode, node)
      else
        path = 'M' + node.point.toArray().join(',')

      lastNode = node

    if @isClosed
      path += makeCurve(@nodes[@nodes.length-1], @nodes[0])
      path += 'Z'

    path

  onNodeChange: (node, eventArgs) =>
    @render()

    index = @_findNodeIndex(node)
    @emit 'change', this, _.extend({index}, eventArgs)

  _bindNode: (node) ->
    node.on 'change', @onNodeChange

  _findNodeIndex: (node) ->
    for i in [0...@nodes.length]
      return i if @nodes[i] == node
    -1

  _createSVGObject: (pathString='') ->
    path = svg.path(pathString).attr(attrs)
    utils.setObjectOnNode(path.node, this)
    path

_.extend(window.Curve, {Path})
