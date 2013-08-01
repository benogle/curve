SVG = window.SVG or require('./vendor/svg').SVG

class SvgDocument
  constructor: (svgContent, rootNode) ->
    @svg = SVG(rootNode)
    window.svg = @svg #FIXME lol
    Curve.import(@svg, svgContent)

    @selectionModel = new Curve.SelectionModel()
    @selectionView = new Curve.SelectionView(@selectionModel)

    @tool = new Curve.PointerTool(@svg, {@selectionModel, @selectionView})
    @tool.activate()

Curve.SvgDocument = SvgDocument
