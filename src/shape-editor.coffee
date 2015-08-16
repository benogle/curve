{CompositeDisposable} = require 'event-kit'
Point = require './point'
Size = require './size'
{normalizePositionAndSize} = require './utils'

# Handles the UI for free-form path editing. Manages NodeEditor objects based on
# a Path's nodes.
module.exports =
class ShapeEditor
  # Fucking SVG renders borders in the center. So on pixel boundaries, a 1px
  # border is a fuzzy 2px. When this number is odd with a 1px border, it
  # produces sharp lines because it places the nodes on a .5 px boundary. Yay.
  handleSize: 9

  cornerPositionByIndex: ['topLeft', 'topRight', 'bottomRight', 'bottomLeft']
  cornerIndexByPosition: null

  constructor: (@svgDocument) ->
    @object = null
    @toolLayer = @svgDocument.getToolLayer()
    @cornerIndexByPosition = {}
    for position, index in @cornerPositionByIndex
      @cornerIndexByPosition[position] = index
    return

  isActive: -> !!@object

  getActiveObject: -> @object

  activateObject: (object) ->
    @deactivate()
    if object?
      @object = object
      @_bindToObject(@object)
      @_setupCornerNodes()
      @render()
      @show()

  deactivate: ->
    @hide()
    @_unbindFromObject()
    @object = null

  hide: ->
    @visible = false
    @cornerHandles?.hide()

  show: (toFront) ->
    @visible = true
    @cornerHandles?.show()

  render: ->
    return unless @object?

    size = @object.get('size')
    position = @object.get('position')

    @renderCorner(@_getPointForCornerPosition('topLeft', position, size), 'topLeft')
    @renderCorner(@_getPointForCornerPosition('topRight', position, size), 'topRight')
    @renderCorner(@_getPointForCornerPosition('bottomRight', position, size), 'bottomRight')
    @renderCorner(@_getPointForCornerPosition('bottomLeft', position, size), 'bottomLeft')

  renderCorner: (point, cornerPosition) ->
    index = @cornerIndexByPosition[cornerPosition]
    corner = @cornerHandles.members[index]
    corner.attr
      x: point.x - @handleSize / 2
      y: point.y - @handleSize / 2
      transform: @object.get('transform')

  ###
  Section: Event Handlers
  ###

  onChangeObject: ({object, value}) ->
    @render() if value.size? or value.position? or value.transform?

  onStartDraggingCornerHandle: (cornerPosition) ->
    @_startSize = @object.get('size')
    @_startPosition = @object.get('position')

  onDraggingCornerHandle: (cornerPosition, delta) ->
    # Technique here is to anchor at the corner _opposite_ the corner the user
    # is dragging, find the new point at the corner we're dragging, then pass
    # that through the normalize function.
    switch cornerPosition
      when 'topLeft'
        anchor = @_getPointForCornerPosition('bottomRight', @_startPosition, @_startSize)
        changedPoint = @_getPointForCornerPosition('topLeft', @_startPosition, @_startSize).add(delta)
      when 'topRight'
        anchor = @_getPointForCornerPosition('bottomLeft', @_startPosition, @_startSize)
        changedPoint = @_getPointForCornerPosition('topRight', @_startPosition, @_startSize).add(delta)
      when 'bottomRight'
        anchor = @_getPointForCornerPosition('topLeft', @_startPosition, @_startSize)
        changedPoint = @_getPointForCornerPosition('bottomRight', @_startPosition, @_startSize).add(delta)
      when 'bottomLeft'
        anchor = @_getPointForCornerPosition('topRight', @_startPosition, @_startSize)
        changedPoint = @_getPointForCornerPosition('bottomLeft', @_startPosition, @_startSize).add(delta)

    @object.set(normalizePositionAndSize(anchor, changedPoint))

  ###
  Section: Private Methods
  ###

  _bindToObject: (object) ->
    return unless object
    @objectSubscriptions = new CompositeDisposable
    @objectSubscriptions.add object.on('change', @onChangeObject.bind(this))

  _unbindFromObject: ->
    @objectSubscriptions?.dispose()
    @objectSubscriptions = null

  _setupCornerNodes: ->
    return if @cornerHandles?
    @cornerHandles = @toolLayer.set()
    @cornerHandles.add(
      @toolLayer.rect(@handleSize, @handleSize),
      @toolLayer.rect(@handleSize, @handleSize),
      @toolLayer.rect(@handleSize, @handleSize),
      @toolLayer.rect(@handleSize, @handleSize)
    )
    @cornerHandles.mousedown (e) =>
      e.stopPropagation()
      false

    for corner, index in @cornerHandles.members
      corner.node.setAttribute('class', 'shape-editor-handle')
      corner.draggable()

      cornerPosition = @cornerPositionByIndex[index]
      corner.dragmove = @onDraggingCornerHandle.bind(this, cornerPosition)
      corner.dragstart = @onStartDraggingCornerHandle.bind(this, cornerPosition)
      corner.dragend = =>
        @_startPosition = null

    return

  _getPointForCornerPosition: (cornerPosition, position, size) ->
    switch cornerPosition
      when 'topLeft'
        position
      when 'topRight'
        position.add([size.width, 0])
      when 'bottomRight'
        position.add([size.width, size.height])
      when 'bottomLeft'
        position.add([0, size.height])
