SVG = require '../test/vendor/svg'

require './curve'
PointerTool = require './pointer-tool'
SelectionModel = require './selection-model'
SelectionView = require './selection-view'

module.exports =
class SvgDocument
  constructor: (svgContent, rootNode)->
    @svg = SVG(rootNode)
    Curve.import(@svg, svgContent)

    @selectionModel = new SelectionModel()
    @selectionView = new SelectionView(selectionModel)

    @tool = new PointerTool(@svg, {selectionModel, selectionView})
    @tool.activate()
