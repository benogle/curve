{CompositeDisposable} = require 'event-kit'
Point = require './point'

# A node UI in the interface allowing for user interaction (moving the node,
# moving the handles). Draws the node, and draws the handles.
# Managed by a PathEditor object.
module.exports =
class NodeEditor
  nodeSize: 5
  handleSize: 3

  node = null
  nodeElement = null
  handleElements = null
  lineElement = null

  constructor: (@svgDocument, @pathEditor) ->
    @toolLayer = @svgDocument.getToolLayer()
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
    @_unbindNode()
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
    @node.setPoint(@_startPosition.add(delta))
  onDraggingHandleIn: (delta, event) =>
    @node.setAbsoluteHandleIn(@_startPosition.add(delta))
  onDraggingHandleOut: (delta, event) =>
    @node.setAbsoluteHandleOut(@_startPosition.add(delta))

  _bindNode: (node) ->
    return unless node
    @nodeSubscriptions = new CompositeDisposable
    @nodeSubscriptions.add node.on('change', @render)
    @nodeSubscriptions.add node.getPath()?.on('change', @render)

  _unbindNode: ->
    @nodeSubscriptions?.dispose()
    @nodeSubscriptions = null

  _setupNodeElement: ->
    @nodeElement = @toolLayer.circle(@nodeSize)
    @nodeElement.node.setAttribute('class', 'node-editor-node')

    @nodeElement.mousedown (e) =>
      e.stopPropagation()
      @setEnableHandles(true)
      @pathEditor.activateNode(@node)
      false

    @nodeElement.draggable()
    @nodeElement.dragmove = @onDraggingNode
    @nodeElement.dragstart = =>
      @pathEditor.activateNode(@node)
      @_startPosition = @node.getPoint()
    @nodeElement.dragend = =>
      @_startPosition = null

    @nodeElement.on 'mouseover', =>
      @nodeElement.front()
      @nodeElement.attr('r': @nodeSize+2)
    @nodeElement.on 'mouseout', =>
      @nodeElement.attr('r': @nodeSize)

  _setupLineElement: ->
    @lineElement = @toolLayer.path('')
    @lineElement.node.setAttribute('class', 'node-editor-lines')

  _setupHandleElements: ->
    self = this

    @handleElements = @toolLayer.set()
    @handleElements.add(
      @toolLayer.circle(@handleSize),
      @toolLayer.circle(@handleSize)
    )
    @handleElements.members[0].node.setAttribute('class', 'node-editor-handle')
    @handleElements.members[1].node.setAttribute('class', 'node-editor-handle')

    @handleElements.mousedown (e) =>
      e.stopPropagation()
      false

    onStopDraggingHandle = =>
      @_draggingHandle = null
      @_startPosition = null

    @handleElements.members[0].draggable()
    @handleElements.members[0].dragmove = @onDraggingHandleIn
    @handleElements.members[0].dragend = onStopDraggingHandle
    @handleElements.members[0].dragstart = ->
      # Use self here as `this` is the SVG element
      self._draggingHandle = this
      self._startPosition = self.node.getAbsoluteHandleIn()

    @handleElements.members[1].draggable()
    @handleElements.members[1].dragmove = @onDraggingHandleOut
    @handleElements.members[1].dragend = onStopDraggingHandle
    @handleElements.members[1].dragstart = ->
      # Use self here as `this` is the SVG element
      self._draggingHandle = this
      self._startPosition = self.node.getAbsoluteHandleOut()

    @handleElements.on 'mouseover', ->
      this.front()
      this.attr('r': self.handleSize+2)
    @handleElements.on 'mouseout', ->
      this.attr('r': self.handleSize)
