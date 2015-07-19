ObjectEditor = require './object-editor.coffee'
Utils = require './Utils.coffee'

module.exports =
class PointerTool
  constructor: (@svgDocument, {@selectionModel, @selectionView, @toolLayer}={}) ->
    @_evrect = @svgDocument.node.createSVGRect();
    @_evrect.width = @_evrect.height = 1;
    @objectEditor = new ObjectEditor(@toolLayer, @selectionModel)

  activate: ->
    @objectEditor.activate()
    @svgDocument.on 'click', @onClick
    @svgDocument.on 'mousemove', @onMouseMove

    objectSelection = @selectionView.getObjectSelection()
    objectSelection.on 'change:object', @onChangedSelectedObject

  deactivate: ->
    @objectEditor.deactivate()
    @svgDocument.off 'click', @onClick
    @svgDocument.off 'mousemove', @onMouseMove

    objectSelection = @selectionView.getObjectSelection()
    objectSelection.off 'change:object', @onChangedSelectedObject

  onChangedSelectedObject: ({object, old}) =>
    if object?
      object.enableDragging()
    else if old?
      old.disableDragging()

  onClick: (e) =>
    # obj = @_hitWithIntersectionList(e)
    obj = @_hitWithTarget(e)
    @selectionModel.setSelected(obj)
    return false if obj

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

    obj = null
    if nodes.length
      for i in [nodes.length-1..0]
        className = nodes[i].getAttribute('class')
        continue if className and className.indexOf('invisible-to-hit-test') > -1
        obj = Utils.getObjectFromNode(nodes[i])
        break

    console.log obj
    obj
