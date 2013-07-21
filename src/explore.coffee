attrs = {fill: '#ccc', stroke: 'none'}
utils = window.Curve

###
  TODO
  * move entire object
  * select/deselect objects
  * make new objects
  * replacing path array updates the interface
###

#
class Path extends EventEmitter
  constructor: () ->
    @path = null
    @nodes = []
    @isClosed = false
    @path = @_createSVGObject()

  addNode: (node) ->
    @_bindNode(node)
    @nodes.push(node)
    @render()

  close: ->
    @isClosed = true
    @render()

  render: (path=@path) ->
    path.attr(d: @toPathString())

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


#
class Point
  @create: (x, y) ->
    return x if x instanceof Point
    new Point(x, y)

  constructor: (x, y) ->
    @set(x, y)

  set: (@x, @y) ->
    [@x, @y] = @x if _.isArray(@x)

  add: (other) ->
    new Point(@x + other.x, @y + other.y)

  subtract: (other) ->
    new Point(@x - other.x, @y - other.y)

  toArray: ->
    [@x, @y]

#
class Curve
  constructor: (@point1, @handle1, @point2, @handle2) ->

#
class Node extends EventEmitter
  constructor: (point, handleIn, handleOut) ->
    @setPoint(point)
    @setHandleIn(handleIn)
    @setHandleOut(handleOut)
    @isJoined = true

  getAbsoluteHandleIn: ->
    @point.add(@handleIn)
  getAbsoluteHandleOut: ->
    @point.add(@handleOut)

  setAbsoluteHandleIn: (point) ->
    @setHandleIn(point.subtract(@point))
  setAbsoluteHandleOut: (point) ->
    @setHandleOut(point.subtract(@point))

  setPoint: (point) ->
    @set('point', Point.create(point))
  setHandleIn: (point) ->
    point = Point.create(point)
    @set('handleIn', point)
    @set('handleOut', new Point(0,0).subtract(point)) if @isJoined
  setHandleOut: (point) ->
    point = Point.create(point)
    @set('handleOut', point)
    @set('handleIn', new Point(0,0).subtract(point)) if @isJoined

  set: (attribute, value) ->
    old = @[attribute]
    @[attribute] = value

    event = "change:#{attribute}"
    eventArgs = {event, value, old}

    @emit event, this, eventArgs
    @emit 'change', this, eventArgs

#
class SelectionModel extends EventEmitter
  constructor: ->
    @selected = null
    @selectedNode = null

  setSelected: (selected) ->
    return if selected == @selected
    old = @selected
    @selected = selected
    @emit 'change:selected', object: @selected, old: old

  setSelectedNode: (selectedNode) ->
    return if selectedNode == @selectedNode
    old = @selectedNode
    @selectedNode = selectedNode
    @emit 'change:selectedNode', node: @selectedNode, old: old

  clearSelected: ->
    @setSelected(null)

  clearSelectedNode: ->
    @setSelectedNode(null)

#
class SelectionView
  nodeSize: 5

  constructor: (@model) ->
    @path = null
    @nodeEditors = []
    @objectSelection = new ObjectSelection()

    @model.on 'change:selected', @onChangeSelected
    @model.on 'change:selectedNode', @onChangeSelectedNode

  onChangeSelected: ({object}) =>
    @setSelectedObject(object)
  onChangeSelectedNode: ({node, old}) =>
    nodeEditor = @_findNodeEditorForNode(old)
    nodeEditor.setEnableHandles(false) if nodeEditor

    nodeEditor = @_findNodeEditorForNode(node)
    nodeEditor.setEnableHandles(true) if nodeEditor

  setSelectedObject: (object) ->
    @objectSelection.setObject(object)
    @_createNodeEditors(object)

  _createNodeEditors: (object) ->
    if object
      nodeDiff = object.nodes.length - @nodeEditors.length
      @nodeEditors.push(new NodeEditor(@model)) for i in [0...nodeDiff] if nodeDiff > 0

    for i in [0...@nodeEditors.length]
      @nodeEditors[i].setNode(object and object.nodes[i] or null)

  _findNodeEditorForNode: (node) ->
    for nodeEditor in @nodeEditors
      return nodeEditor if nodeEditor.node == node
    null

#
class ObjectSelection
  constructor: ->

  setObject: (object) ->
    @_unbindObject(@object)
    @object = object
    @_bindObject(@object)

    @path.remove() if @path
    @path = null
    if @object
      @path = svg.path('').front()
      @path.node.setAttribute('class', 'object-selection')
      @render()

  render: =>
    @object.render(@path)

  _bindObject: (object) ->
    return unless object
    object.on 'change', @render

  _unbindObject: (object) ->
    return unless object
    object.off 'change', @render

#
class NodeEditor
  nodeSize: 5
  handleSize: 3

  node = null
  nodeElement = null
  handleElements = null
  lineElement = null

  constructor: (@selectionModel) ->
    @_setupNodeElement()
    @_setupLineElement()
    @_setupHandleElements()
    @hide()

  hide: ->
    @visible = false
    @lineElement.hide()
    @nodeElement.hide()
    @handleElements.hide()

  show: ->
    @visible = true
    @lineElement.front()
    @nodeElement.front().show()
    @handleElements.front()

    if @enableHandles
      @lineElement.show()
      @handleElements.show()
    else
      @lineElement.hide()
      @handleElements.hide()

  setEnableHandles: (@enableHandles) ->
    @show() if @visible

  setNode: (node) ->
    @_unbindNode(@node)
    @node = node
    @_bindNode(@node)
    @setEnableHandles(false)
    @render()

  render: =>
    return @hide() unless @node

    handleIn = @node.getAbsoluteHandleIn()
    handleOut = @node.getAbsoluteHandleOut()
    point = @node.point

    linePath = "M#{handleIn.x},#{handleIn.y}L#{point.x},#{point.y}L#{handleOut.x},#{handleOut.y}"
    @lineElement.attr(d: linePath)

    @handleElements.members[0].attr(cx: handleIn.x, cy: handleIn.y)
    @handleElements.members[1].attr(cx: handleOut.x, cy: handleOut.y)

    @nodeElement.attr(cx: point.x, cy: point.y)

    @show()

    # make sure the handlethe user is dragging is on top. could get in the
    # situation where the handle passed under the other, and it feels weird.
    @_draggingHandle.front() if @_draggingHandle

  onDraggingNode: (delta, event) =>
    @node.setPoint(new Point(event.clientX, event.clientY))
  onDraggingHandleIn: (delta, event) =>
    @node.setAbsoluteHandleIn(new Point(event.clientX, event.clientY))
  onDraggingHandleOut: (delta, event) =>
    @node.setAbsoluteHandleOut(new Point(event.clientX, event.clientY))

  _bindNode: (node) ->
    return unless node
    node.on 'change', @render
  _unbindNode: (node) ->
    return unless node
    node.off 'change', @render

  _setupNodeElement: ->
    @nodeElement = svg.circle(@nodeSize)
    @nodeElement.node.setAttribute('class', 'node-editor-node')

    @nodeElement.click => @selectionModel.setSelectedNode(@node)

    @nodeElement.draggable()
    @nodeElement.dragstart = => @selectionModel.setSelectedNode(@node)
    @nodeElement.dragmove = @onDraggingNode
    # @nodeElement.hover =>
    #   @nodeElement.attr('r': @nodeSize+2)
    # , =>
    #   @nodeElement.attr('r': @nodeSize)

  _setupLineElement: ->
    @lineElement = svg.path('')
    @lineElement.node.setAttribute('class', 'node-editor-lines')

  _setupHandleElements: ->
    self = this

    @handleElements = svg.set()
    @handleElements.add(
      svg.circle(@handleSize),
      svg.circle(@handleSize)
    )
    @handleElements.members[0].node.setAttribute('class', 'node-editor-handle')
    @handleElements.members[1].node.setAttribute('class', 'node-editor-handle')

    onStartDraggingHandle = ->
      self._draggingHandle = this
    onStopDraggingHandle = ->
      self._draggingHandle = null

    @handleElements.members[0].draggable()
    @handleElements.members[0].dragmove = @onDraggingHandleIn
    @handleElements.members[0].dragstart = onStartDraggingHandle
    @handleElements.members[0].dragend = onStopDraggingHandle

    @handleElements.members[1].draggable()
    @handleElements.members[1].dragmove = @onDraggingHandleOut
    @handleElements.members[1].dragstart = onStartDraggingHandle
    @handleElements.members[1].dragend = onStopDraggingHandle

    # @handleElements.hover ->
    #   this.front()
    #   this.attr('r': self.handleSize+2)
    # , ->
    #   this.attr('r': self.handleSize)


_.extend(window.Curve, {Path, Curve, Point, Node, SelectionModel, SelectionView, NodeEditor})

window.main = ->
  @svg = SVG("canvas")
  @path = new Path()
  @path.addNode(new Node([50, 50], [-10, 0], [10, 0]))
  @path.addNode(new Node([80, 60], [-10, -5], [10, 5]))
  @path.addNode(new Node([60, 80], [10, 0], [-10, 0]))
  @path.close()

  @selectionModel = new SelectionModel()
  @selectionView = new SelectionView(selectionModel)

  @selectionModel.setSelected(@path)
  @selectionModel.setSelectedNode(@path.nodes[2])
