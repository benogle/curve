#
class Curve.PenTool
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
