{SVG} = require '../test/vendor/svg'

require '../test/vendor/svg.circle.js'
require '../test/vendor/svg.draggable.js'
require './_module'
require './import'
PointerTool = require './pointer-tool'
SelectionModel = require './selection-model'
SelectionView = require './selection-view'

module.exports =
class SvgDocument
  constructor: (svgContent, rootNode) ->
    @svg = SVG(rootNode)
    window.svg = @svg #FIXME lol
    Curve.import(@svg, svgContent)

    @selectionModel = new SelectionModel()
    @selectionView = new SelectionView(@selectionModel)

    @tool = new PointerTool(@svg, {@selectionModel, @selectionView})
    @tool.activate()
