{Emitter} = require 'event-kit'
SVG = require '../vendor/svg'

SelectionModel = require "./selection-model"
SelectionView = require "./selection-view"
PointerTool = require "./pointer-tool"
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

  setSize: (size) ->
    size = Size.create(size)
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
    @selectionView = new SelectionView(@toolLayer, @selectionModel)

    @tool = new PointerTool(@svg, {@selectionModel, @selectionView, @toolLayer})
    @tool.activate()

    @model.on('change:size', @onChangedSize)

  deserialize: (svgString) ->
    @model.setObjects(DeserializeSVG(@svg, svgString))
    root = @getSvgRoot()
    @model.setSize(new Size(root.width(), root.height()))
    @toolLayer.front()

  serialize: ->
    svgRoot = @getSvgRoot()
    if svgRoot
      SerializeSVG(svgRoot, whitespace: true)
    else
      ''

  getSvgRoot: ->
    svgRoot = null
    @svg.each -> svgRoot = this if this.node.nodeName == 'svg'
    svgRoot

  ###
  Section: Model Delegates
  ###

  setSize: (size) -> @model.setSize(size)

  getSize: -> @model.getSize()

  getObjects: -> @model.getObjects()

  on: (args...) -> @model.on(args...)

  ###
  Section: Event Handlers
  ###

  onChangedSize: ({size}) =>
    root = @getSvgRoot()
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
