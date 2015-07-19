SVG = require '../vendor/svg'

SelectionModel = require "./selection-model.coffee"
SelectionView = require "./selection-view.coffee"
PointerTool = require "./pointer-tool.coffee"
DeserializeSVG = require "./deserialize-svg.coffee"

module.exports =
class SVGDocument
  constructor: (rootNode) ->
    @objects = []
    @svgDocument = SVG(rootNode)

    @toolLayer = @svgDocument.group()
    @toolLayer.node.setAttribute('class', 'tool-layer')

    @selectionModel = new SelectionModel()
    @selectionView = new SelectionView(@toolLayer, @selectionModel)

    @tool = new PointerTool(@svgDocument, {@selectionModel, @selectionView, @toolLayer})
    @tool.activate()

  deserialize: (svgString) ->
    @objects = DeserializeSVG(@svgDocument, svgString)
    @toolLayer.front()

  serialize: ->
    svgRoot = @getSvgRoot()
    if svgRoot
      svgRoot.export(whitespace: true)
    else
      ''

  getSvgRoot: ->
    svgRoot = null
    @svgDocument.each -> svgRoot = this if this.node.nodeName == 'svg'
    svgRoot
