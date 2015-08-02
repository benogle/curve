{EventEmitter} = require 'events'
SVG = require '../vendor/svg'

SelectionModel = require "./selection-model"
SelectionView = require "./selection-view"
PointerTool = require "./pointer-tool"
SerializeSVG = require "./serialize-svg"
DeserializeSVG = require "./deserialize-svg"
Size = require "./size"

class SVGDocumentModel extends EventEmitter
  constructor: ->
    @objects = []

  setObjects: (@objects) ->

  getObjects: -> @objects

  setSize: (size) ->
    size = Size.create(size)
    return if size.equals(@size)
    @size = size
    @emit 'change:size', {size}

  getSize: -> @size

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

  addListener: (args...) -> @model.addListener(args...)

  removeListener: (args...) -> @model.removeListener(args...)

  ###
  Section: Event Handlers
  ###

  onChangedSize: ({size}) =>
    root = @getSvgRoot()
    root.width(size.width)
    root.height(size.height)
