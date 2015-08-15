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
    svg = @svgDocument.getSVGRoot()
    svg.on 'mousedown', @onMouseDown
    svg.on 'mousemove', @onMouseMove
    svg.on 'mouseup', @onMouseUp
    @active = true

  deactivate: ->
    @objectEditor.deactivate()
    svg = @svgDocument.getSVGRoot()
    svg.off 'mousedown', @onMouseDown
    svg.off 'mousemove', @onMouseMove
    svg.off 'mouseup', @onMouseUp
    @active = false

  onMouseDown: (e) =>
    makeNode = =>
      position = getCanvasPosition(@svgDocument.getSVGRoot(), e)
      @currentNode = new Node(position, [0, 0], [0, 0], true)
      @currentObject.addNode(@currentNode)
      @selectionModel.setSelectedNode(@currentNode)

    if @currentObject
      # if @selectionView.nodeEditors.length and e.target == @selectionView.nodeEditors[0].nodeElement.node
      #   @currentObject.close()
      #   @currentObject = null
      # else
      makeNode()
    else
      @currentObject = new Path(@svgDocument)
      @selectionModel.setSelected(@currentObject)
      makeNode()

  onMouseMove: (e) =>
    if @currentNode
      position = getCanvasPosition(@svgDocument.getSVGRoot(), e)
      @currentNode.setAbsoluteHandleOut(position)

  onMouseUp: (e) =>
    @currentNode = null
