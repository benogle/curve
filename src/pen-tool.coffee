Node = require './node'
Path = require './path'

#
module.exports =
class PenTool
  currentObject: null
  currentNode: null

  constructor: (@svgDocument, {@selectionModel, @selectionView}={}) ->

  activate: ->
    @svgDocument.on 'mousedown', @onMouseDown
    @svgDocument.on 'mousemove', @onMouseMove
    @svgDocument.on 'mouseup', @onMouseUp

  deactivate: ->
    @svgDocument.removeListener 'mousedown', @onMouseDown
    @svgDocument.removeListener 'mousemove', @onMouseMove
    @svgDocument.removeListener 'mouseup', @onMouseUp

  onMouseDown: (e) =>
    makeNode = =>
      @currentNode = new Node([e.clientX, e.clientY], [0, 0], [0, 0])
      @currentObject.addNode(@currentNode)
      @selectionModel.setSelectedNode(@currentNode)

    if @currentObject
      if @selectionView.nodeEditors.length and e.target == @selectionView.nodeEditors[0].nodeElement.node
        @currentObject.close()
        @currentObject = null
      else
        makeNode()
    else
      @currentObject = new Path(@svgDocument)
      @selectionModel.setSelected(@currentObject)
      makeNode()

  onMouseMove: (e) =>
    @currentNode.setAbsoluteHandleOut([e.clientX, e.clientY]) if @currentNode

  onMouseUp: (e) =>
    @currentNode = null
