_ = window._ or require 'underscore'
$ = window.jQuery or require 'jquery'

# A node UI in the interface allowing for user interaction (moving the node,
# moving the handles). Draws the node, and draws the handles.
# Managed by a PathEditor object.
class NodeEditor
  nodeSize: 5
  handleSize: 3

  node = null
  nodeElement = null
  handleElements = null
  lineElement = null

  constructor: (@svgToolParent, @pathEditor) ->
    @svgDocument = @svgToolParent.parent
    @_setupNodeElement()
    @_setupLineElement()
    @_setupHandleElements()
    @hide()

  hide: ->
    @visible = false
    @lineElement.hide()
    @nodeElement.hide()
    @handleElements.hide()

  show: (toFront) ->
    @visible = true
    @nodeElement.show()

    if toFront
      @lineElement.front()
      @nodeElement.front()
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
    point = @node.getPoint()

    linePath = "M#{handleIn.x},#{handleIn.y}L#{point.x},#{point.y}L#{handleOut.x},#{handleOut.y}"
    @lineElement.attr(d: linePath)

    # Note nulling out the transform; the svg lib is a dick and adds them in
    # when setting the center attributes. Not sure why.
    @handleElements.members[0].attr(cx: handleIn.x, cy: handleIn.y, transform: '')
    @handleElements.members[1].attr(cx: handleOut.x, cy: handleOut.y, transform: '')
    @nodeElement.attr(cx: point.x, cy: point.y, transform: '')

    @show()

    # make sure the handle the user is dragging is on top. could get in the
    # situation where the handle passed under the other, and it feels weird.
    @_draggingHandle.front() if @_draggingHandle

  onDraggingNode: (delta, event) =>
    @node.setPoint(@pointForEvent(event))
  onDraggingHandleIn: (delta, event) =>
    @node.setAbsoluteHandleIn(@pointForEvent(event))
  onDraggingHandleOut: (delta, event) =>
    @node.setAbsoluteHandleOut(@pointForEvent(event))

  pointForEvent: (event) ->
    {clientX, clientY} = event
    {top, left} = $(@svgDocument.node).offset()
    new Curve.Point(event.clientX - left, event.clientY - top)

  _bindNode: (node) ->
    return unless node
    node.addListener 'change', @render
    node.getPath()?.addListener 'change', @render

  _unbindNode: (node) ->
    return unless node
    node.removeListener 'change', @render
    node.getPath()?.addListener 'change', @render

  _setupNodeElement: ->
    @nodeElement = @svgToolParent.circle(@nodeSize)
    @nodeElement.node.setAttribute('class', 'node-editor-node')

    @nodeElement.click (e) =>
      e.stopPropagation()
      @setEnableHandles(true)
      @pathEditor.activateNode(@node)
      false

    @nodeElement.draggable()
    @nodeElement.dragstart = => @pathEditor.activateNode(@node)
    @nodeElement.dragmove = @onDraggingNode
    @nodeElement.on 'mouseover', =>
      @nodeElement.front()
      @nodeElement.attr('r': @nodeSize+2)
    @nodeElement.on 'mouseout', =>
      @nodeElement.attr('r': @nodeSize)

  _setupLineElement: ->
    @lineElement = @svgToolParent.path('')
    @lineElement.node.setAttribute('class', 'node-editor-lines')

  _setupHandleElements: ->
    self = this

    @handleElements = @svgToolParent.set()
    @handleElements.add(
      @svgToolParent.circle(@handleSize),
      @svgToolParent.circle(@handleSize)
    )
    @handleElements.members[0].node.setAttribute('class', 'node-editor-handle')
    @handleElements.members[1].node.setAttribute('class', 'node-editor-handle')

    @handleElements.click (e) =>
      e.stopPropagation()
      false

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

    @handleElements.on 'mouseover', ->
      this.front()
      this.attr('r': self.handleSize+2)
    @handleElements.on 'mouseout', ->
      this.attr('r': self.handleSize)

Curve.NodeEditor = NodeEditor
