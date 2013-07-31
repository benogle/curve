_ = require 'underscore'

utils = window.Curve

{Point} = window.Curve

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

_.extend(window.Curve, {NodeEditor})
