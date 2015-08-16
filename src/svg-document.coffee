{Emitter} = require 'event-kit'
SVG = require '../vendor/svg'

SelectionModel = require "./selection-model"
SelectionView = require "./selection-view"
PenTool = require "./pen-tool"
PointerTool = require "./pointer-tool"
ShapeTool = require "./shape-tool"
SerializeSVG = require "./serialize-svg"
DeserializeSVG = require "./deserialize-svg"
Size = require "./size"
Point = require "./point"
ObjectEditor = require './object-editor'
SVGDocumentModel = require "./svg-document-model"

module.exports =
class SVGDocument
  constructor: (rootNode) ->
    @emitter = new Emitter
    @model = new SVGDocumentModel
    @svg = SVG(rootNode)

    @toolLayer = @svg.group()
    @toolLayer.node.setAttribute('class', 'tool-layer')

    @selectionModel = new SelectionModel()
    @selectionView = new SelectionView(this)
    @objectEditor = new ObjectEditor(this)

    @model.on('change:size', @onChangedSize)

    # delegate model events
    @model.on 'change', (event) => @emitter.emit('change', event)
    @model.on 'change:size', (event) => @emitter.emit('change:size', event)

  on: (args...) -> @emitter.on(args...)

  initializeTools: ->
    @tools = [
      new PointerTool(this)
      new PenTool(this)
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
    oldActiveToolType = oldActiveTool?.getType()

    newTool = @toolForType(toolType)
    if newTool? and toolType isnt oldActiveToolType
      oldActiveTool?.deactivate()
      newTool.activate(toolType)
      @emitter.emit('change:tool', {toolType})

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

  getObjectEditor: -> @objectEditor

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
    # TODO: this could ask the active tool to move the selected objects
    return unless deltaPoint
    deltaPoint = Point.create(deltaPoint)

    if selectedNode = @selectionModel.getSelectedNode()
      selectedNode?.translate?(deltaPoint)
    else if selectedObject = @selectionModel.getSelected()
      selectedObject?.translate?(deltaPoint)

  removeSelectedObjects: ->
    # TODO: this could ask the active tool to remove the selected objects
    selectedObject = @selectionModel.getSelected()

    if selectedObject and (selectedNode = @selectionModel.getSelectedNode())
      selectedObject.removeNode?(selectedNode)
    else
      selectedObject?.remove()

  registerObject: (object) ->
    @model.registerObject(object)

  _createObjectLayer: ->
    @objectLayer = @svg.nested()
    @setSize(1024, 1024)
    @objectLayer.back()
