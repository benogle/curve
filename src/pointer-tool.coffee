ObjectEditor = require './object-editor'
Utils = require './Utils'

module.exports =
class PointerTool
  constructor: (@svgDocument, {@selectionModel, @selectionView, @toolLayer}={}) ->
    @_evrect = @svgDocument.node.createSVGRect();
    @_evrect.width = @_evrect.height = 1;
    @objectEditor = new ObjectEditor(@toolLayer, @selectionModel)

  activate: ->
    @objectEditor.activate()
    @svgDocument.on 'mousedown', @onMouseDown
    @svgDocument.on 'mousemove', @onMouseMove

    objectSelection = @selectionView.getObjectSelection()
    @changeSubscriptions = objectSelection.on('change:object', @onChangedSelectedObject)

  deactivate: ->
    @objectEditor.deactivate()
    @svgDocument.off 'mousedown', @onMouseDown
    @svgDocument.off 'mousemove', @onMouseMove

    @changeSubscriptions?.dispose()
    @changeSubscriptions = null

  onChangedSelectedObject: ({object, old}) =>
    if object?
      object.enableDragging()
    else if old?
      old.disableDragging()

  onMouseDown: (event) =>
    # obj = @_hitWithIntersectionList(event)
    object = @_hitWithTarget(event)
    object?.enableDragging?(event)
    @selectionModel.setSelected(object)
    # return false if obj
    true

  onMouseMove: (e) =>
    # @selectionModel.setPreselected(@_hitWithIntersectionList(e))
    @selectionModel.setPreselected(@_hitWithTarget(e))

  _hitWithTarget: (e) ->
    obj = null
    obj = Utils.getObjectFromNode(e.target) if e.target != @svgDocument.node
    obj

  # This seems slower and more complicated than _hitWithTarget
  _hitWithIntersectionList: (e) ->
    top = @svgDocument.node.offsetTop
    left = @svgDocument.node.offsetLeft
    @_evrect.x = e.clientX - left
    @_evrect.y = e.clientY - top
    nodes = @svgDocument.node.getIntersectionList(@_evrect, null)

    if nodes.length
      for i in [nodes.length-1..0]
        className = nodes[i].getAttribute('class')
        continue if className and className.indexOf('invisible-to-hit-test') > -1
        return Utils.getObjectFromNode(nodes[i])
    null
