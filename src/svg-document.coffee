{Emitter} = require 'event-kit'
SVG = require '../vendor/svg'

SelectionModel = require "./selection-model"
SelectionView = require "./selection-view"
PointerTool = require "./pointer-tool"
ShapeTool = require "./shape-tool"
SerializeSVG = require "./serialize-svg"
DeserializeSVG = require "./deserialize-svg"
Size = require "./size"
Point = require "./point"

class SVGDocumentModel
  constructor: ->
    @emitter = new Emitter
    @objects = []

  on: (args...) -> @emitter.on(args...)

  setObjects: (@objects) ->
    for object in @objects
      object.on 'change', @onChangedObject
    return

  getObjects: -> @objects

  setSize: (w, h) ->
    size = Size.create(w, h)
    return if size.equals(@size)
    @size = size
    @emitter.emit 'change:size', {size}

  getSize: -> @size

  onChangedObject: (event) =>
    @emitter.emit 'change', event

module.exports =
class SVGDocument
  constructor: (rootNode) ->
    @model = new SVGDocumentModel
    @svg = SVG(rootNode)

    @toolLayer = @svg.group()
    @toolLayer.node.setAttribute('class', 'tool-layer')

    @selectionModel = new SelectionModel()
    @selectionView = new SelectionView(this)

    @model.on('change:size', @onChangedSize)

  initializeTools: ->
    @tools = [
      new PointerTool(this)
      new ShapeTool(this)
    ]

    for tool in @tools
      tool.on?('cancel', => @setActiveToolType('pointer'))

    @setActiveToolType('pointer')

  ###
  Section: File Serialization
  ###

  deserialize: (svgString) ->
    @model.setObjects(DeserializeSVG(this, svgString))

    objectLayer = null
    @svg.each -> objectLayer = this if this.node.nodeName == 'svg'
    @objectLayer = objectLayer
    objectLayer = @getObjectLayer() unless objectLayer?

    @model.setSize(new Size(objectLayer.width(), objectLayer.height()))
    @toolLayer.front()
    return

  serialize: ->
    svgRoot = @getObjectLayer()
    if svgRoot
      SerializeSVG(svgRoot, whitespace: true)
    else
      ''

  ###
  Section: Tool Management
  ###

  toolForType: (toolType) ->
    for tool in @tools
      return tool if tool.supportsType(toolType)
    null

  getActiveTool: ->
    for tool in @tools
      return tool if tool.isActive()
    null

  getActiveToolType: ->
    @getActiveTool()?.getType()

  setActiveToolType: (toolType) ->
    oldActiveTool = @getActiveTool()

    newTool = @toolForType(toolType)
    if newTool? and newTool isnt oldActiveTool
      oldActiveTool?.deactivate()
      newTool.activate(toolType)

  ###
  Section: Selections
  ###

  getSelectionModel: -> @selectionModel

  getSelectionView: -> @selectionView

  ###
  Section: SVG Details
  ###

  getSVGRoot: -> @svg

  getToolLayer: -> @toolLayer

  getObjectLayer: ->
    @objectLayer = @_createObjectLayer() unless @objectLayer?
    @objectLayer

  ###
  Section: Document Details
  ###

  setSize: (w, h) -> @model.setSize(w, h)

  getSize: -> @model.getSize()

  getObjects: -> @model.getObjects()

  on: (args...) -> @model.on(args...)

  ###
  Section: Event Handlers
  ###

  onChangedSize: ({size}) =>
    root = @getObjectLayer()
    root.width(size.width)
    root.height(size.height)

  ###
  Section: Acting on selected elements
  ###

  translateSelectedObjects: (deltaPoint) ->
    return unless deltaPoint
    deltaPoint = Point.create(deltaPoint)

    selectedObject = @selectionModel.getSelected()
    selectedObject?.translate?(deltaPoint)

  _createObjectLayer: ->
    @objectLayer = @svg.nested()
    @setSize(1024, 1024)
    @objectLayer
