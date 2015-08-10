ObjectEditor = require './object-editor'
Utils = require './Utils'

module.exports =
class PointerTool
  constructor: (@svgDocument) ->
    @_evrect = @svgDocument.getSVGRoot().node.createSVGRect();
    @_evrect.width = @_evrect.height = 1;

    @selectionModel = @svgDocument.getSelectionModel()
    @selectionView =  @svgDocument.getSelectionView()
    @toolLayer = @svgDocument.getToolLayer()

    @objectEditor = new ObjectEditor(@svgDocument)

  getType: -> 'pointer'

  supportsType: (type) -> type is 'pointer'

  isActive: -> @active

  activate: ->
    @objectEditor.activate()
    svg = @svgDocument.getSVGRoot()
    svg.on 'mousedown', @onMouseDown
    svg.on 'mousemove', @onMouseMove

    objectSelection = @selectionView.getObjectSelection()
    @changeSubscriptions = objectSelection.on('change:object', @onChangedSelectedObject)
    @active = true

  deactivate: ->
    @objectEditor.deactivate()
    svg = @svgDocument.getSVGRoot()
    svg.off 'mousedown', @onMouseDown
    svg.off 'mousemove', @onMouseMove

    @selectionModel.getSelected()?.disableDragging?()

    @changeSubscriptions?.dispose()
    @changeSubscriptions = null
    @active = false

  onChangedSelectedObject: ({object, old}) =>
    object.enableDragging() if object?
    old.disableDragging() if old?

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
    obj = Utils.getObjectFromNode(e.target) if e.target != @svgDocument.getSVGRoot().node
    obj

  # This seems slower and more complicated than _hitWithTarget
  _hitWithIntersectionList: (e) ->
    svgNode = @svgDocument.getSVGRoot().node
    top = svgNode.offsetTop
    left = svgNode.offsetLeft
    @_evrect.x = e.clientX - left
    @_evrect.y = e.clientY - top
    nodes = svgNode.getIntersectionList(@_evrect, null)

    if nodes.length
      for i in [nodes.length-1..0]
        className = nodes[i].getAttribute('class')
        continue if className and className.indexOf('invisible-to-hit-test') > -1
        return Utils.getObjectFromNode(nodes[i])
    null
