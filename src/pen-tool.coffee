Node = require './node'
Path = require './path'
{getCanvasPosition} = require './utils'

module.exports =
class PenTool
  currentObject: null
  currentNode: null

  constructor: (@svgDocument) ->
    @selectionModel = @svgDocument.getSelectionModel()
    @objectEditor = @svgDocument.getObjectEditor()

  getType: -> 'pen'

  supportsType: (type) -> type is 'pen'

  isActive: -> @active

  activate: ->
    @objectEditor.activate()
    @subscriptions = @objectEditor.editors.Path.on('mousedown:node', @onMouseDownNode.bind(this))
    svg = @svgDocument.getSVGRoot()
    svg.on 'mousedown', @onMouseDown
    svg.on 'mousemove', @onMouseMove
    svg.on 'mouseup', @onMouseUp
    @active = true

  deactivate: ->
    @objectEditor.deactivate()
    @subscriptions?.dispose()
    svg = @svgDocument.getSVGRoot()
    svg.off 'mousedown', @onMouseDown
    svg.off 'mousemove', @onMouseMove
    svg.off 'mouseup', @onMouseUp
    @active = false

  onMouseDownNode: (event) ->
    {node} = event
    path = @selectionModel.getSelected()
    if path?
      nodeIndex = path.getNodes().indexOf(node)
      path.close() if nodeIndex is 0

  onMouseDown: (event) =>
    unless @currentObject
      @currentObject = new Path(@svgDocument)
      @selectionModel.setSelected(@currentObject)

    position = getCanvasPosition(@svgDocument.getSVGRoot(), event)
    @currentNode = new Node(position, [0, 0], [0, 0], true)
    @currentObject.addNode(@currentNode)
    @selectionModel.setSelectedNode(@currentNode)

  onMouseMove: (e) =>
    if @currentNode
      position = getCanvasPosition(@svgDocument.getSVGRoot(), e)
      @currentNode.setAbsoluteHandleOut(position)

  onMouseUp: (e) =>
    @currentNode = null
