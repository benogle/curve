attrs = {fill: '#ccc', stroke: 'none'}
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
    other = Point.create(other)
    new Point(@x + other.x, @y + other.y)

  subtract: (other) ->
    other = Point.create(other)
    new Point(@x - other.x, @y - other.y)

  toArray: ->
    [@x, @y]

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
    @setHandleIn(Point.create(point).subtract(@point))
  setAbsoluteHandleOut: (point) ->
    @setHandleOut(Point.create(point).subtract(@point))

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
    @preselected = null
    @selected = null
    @selectedNode = null

  setPreselected: (preselected) ->
    return if preselected == @preselected
    old = @preselected
    @preselected = preselected
    @emit 'change:preselected', object: @preselected, old: old

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
  clearPreselected: ->
    @setPreselected(null)
  clearSelectedNode: ->
    @setSelectedNode(null)

#
class SelectionView
  nodeSize: 5

  constructor: (@model) ->
    @path = null
    @nodeEditors = []
    @_nodeEditorStash = []

    @objectSelection = new ObjectSelection()
    @objectPreselection = new ObjectSelection(class: 'object-preselection')

    @model.on 'change:selected', @onChangeSelected
    @model.on 'change:preselected', @onChangePreselected
    @model.on 'change:selectedNode', @onChangeSelectedNode

  onChangeSelected: ({object, old}) =>
    @_unbindFromObject(old)
    @_bindToObject(object)
    @setSelectedObject(object)
  onChangePreselected: ({object}) =>
    @objectPreselection.setObject(object)
  onChangeSelectedNode: ({node, old}) =>
    nodeEditor = @_findNodeEditorForNode(old)
    nodeEditor.setEnableHandles(false) if nodeEditor

    nodeEditor = @_findNodeEditorForNode(node)
    nodeEditor.setEnableHandles(true) if nodeEditor

  setSelectedObject: (object) ->
    @objectSelection.setObject(object)
    @_createNodeEditors(object)

  onInsertNode: (object, {node, index}={}) =>
    @_insertNodeEditor(object, index)
    null # Force null. _insertNodeEditor returns true and tells event emitter 'once'. Ugh

  _bindToObject: (object) ->
    return unless object
    object.on 'insert:node', @onInsertNode

  _unbindFromObject: (object) ->
    return unless object
    object.off 'insert:node', @onInsertNode

  _createNodeEditors: (object) ->
    @_nodeEditorStash = @nodeEditors
    @nodeEditors = []

    if object
      for i in [0...object.nodes.length]
        @_insertNodeEditor(object, i)

    for nodeEditor in @_nodeEditorStash
      nodeEditor.setNode(null)

  _insertNodeEditor: (object, index) ->
    return false unless object and object.nodes[index]

    nodeEditor = if @_nodeEditorStash.length
      @_nodeEditorStash.pop()
    else
      new NodeEditor(@model)

    nodeEditor.setNode(object.nodes[index])
    @nodeEditors.splice(index, 0, nodeEditor)
    true

  _findNodeEditorForNode: (node) ->
    for nodeEditor in @nodeEditors
      return nodeEditor if nodeEditor.node == node
    null

#
class ObjectSelection
  constructor: (@options={}) ->
    @options.class ?= 'object-selection'

  setObject: (object) ->
    @_unbindObject(@object)
    @object = object
    @_bindObject(@object)

    @path.remove() if @path
    @path = null
    if @object
      @path = svg.path('').front()
      @path.node.setAttribute('class', @options.class + ' invisible-to-hit-test')
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

    @nodeElement.click (e) =>
      e.stopPropagation()
      @selectionModel.setSelectedNode(@node)
      false

    @nodeElement.draggable()
    @nodeElement.dragstart = => @selectionModel.setSelectedNode(@node)
    @nodeElement.dragmove = @onDraggingNode
    @nodeElement.on 'mouseover', =>
      @nodeElement.attr('r': @nodeSize+2)
    @nodeElement.on 'mouseout', =>
      @nodeElement.attr('r': @nodeSize)

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

    # I hate this.
    find = (el) =>
      return @handleElements.members[0] if @handleElements.members[0].node == el
      @handleElements.members[1]

    @handleElements.on 'mouseover', ->
      el = find(this)
      el.front()
      el.attr('r': self.handleSize+2)
    @handleElements.on 'mouseout', ->
      el = find(this)
      el.attr('r': self.handleSize)

class PointerTool
  constructor: (svg, {@selectionModel, @selectionView}={}) ->
    @_evrect = svg.node.createSVGRect();
    @_evrect.width = @_evrect.height = 1;

  activate: ->
    svg.on 'click', @onClick
    svg.on 'mousemove', @onMouseMove

  deactivate: ->
    svg.off 'click', @onClick
    svg.off 'mousemove', @onMouseMove

  onClick: (e) =>
    obj = @_hitWithIntersectionList(e)
    @selectionModel.setSelected(obj)
    return false if obj

  onMouseMove: (e) =>
    @selectionModel.setPreselected(@_hitWithIntersectionList(e))
    # @selectionModel.setPreselected(@_hitWithTarget(e))

  _hitWithTarget: (e) ->
    obj = null
    obj = utils.getObjectFromNode(e.target) if e.target != svg.node
    obj

  _hitWithIntersectionList: (e) ->
    @_evrect.x = e.clientX
    @_evrect.y = e.clientY
    nodes = svg.node.getIntersectionList(@_evrect, null)

    obj = null
    if nodes.length
      for i in [nodes.length-1..0]
        clas = nodes[i].getAttribute('class')
        continue if clas and clas.indexOf('invisible-to-hit-test') > -1
        obj = utils.getObjectFromNode(nodes[i])
        break

    obj

class PenTool
  currentObject: null
  currentNode: null

  constructor: (svg, {@selectionModel, @selectionView}={}) ->

  activate: ->
    svg.on 'mousedown', @onMouseDown
    svg.on 'mousemove', @onMouseMove
    svg.on 'mouseup', @onMouseUp

  deactivate: ->
    svg.off 'mousedown', @onMouseDown
    svg.off 'mousemove', @onMouseMove
    svg.off 'mouseup', @onMouseUp

  onMouseDown: (e) =>
    makeNode = =>
      @currentNode = new Curve.Node([e.clientX, e.clientY], [0, 0], [0, 0])
      @currentObject.addNode(@currentNode)
      @selectionModel.setSelectedNode(@currentNode)

    if @currentObject
      if @selectionView.nodeEditors.length and e.target == @selectionView.nodeEditors[0].nodeElement.node
        @currentObject.close()
        @currentObject = null
      else
        makeNode()
    else
      @currentObject = new Curve.Path()
      @selectionModel.setSelected(@currentObject)
      makeNode()

  onMouseMove: (e) =>
    @currentNode.setAbsoluteHandleOut([e.clientX, e.clientY]) if @currentNode

  onMouseUp: (e) =>
    @currentNode = null

_.extend(window.Curve, {Path, Curve, Point, Node, SelectionModel, SelectionView, NodeEditor})

window.main = ->
  @svg = SVG("canvas")

  @path1 = new Path()
  @path1.addNode(new Node([50, 50], [-10, 0], [10, 0]))
  @path1.addNode(new Node([80, 60], [-10, -5], [10, 5]))
  @path1.addNode(new Node([60, 80], [10, 0], [-10, 0]))
  @path1.close()

  @path2 = new Path()
  @path2.addNode(new Node([150, 50], [-10, 0], [10, 0]))
  @path2.addNode(new Node([220, 100], [-10, -5], [10, 5]))
  @path2.addNode(new Node([160, 120], [10, 0], [-10, 0]))
  @path2.close()

  @path2.path.attr
    fill: 'none'
    stroke: '#333'
    'stroke-width': 2

  @selectionModel = new SelectionModel()
  @selectionView = new SelectionView(selectionModel)

  @selectionModel.setSelected(@path1)
  @selectionModel.setSelectedNode(@path1.nodes[2])

  @tool = new PointerTool(@svg, {selectionModel, selectionView})
  # @tool.activate()

  @pen = new PenTool(@svg, {selectionModel, selectionView})
  @pen.activate()
