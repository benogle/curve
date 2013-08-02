SVG = window.SVG or require('./vendor/svg').SVG

class SvgDocument
  constructor: (svgContent, rootNode) ->
    @svgDocument = SVG(rootNode)
    Curve.import(@svgDocument, svgContent)

    @selectionModel = new Curve.SelectionModel()
    @selectionView = new Curve.SelectionView(@svgDocument, @selectionModel)

    @tool = new Curve.PointerTool(@svgDocument, {@selectionModel, @selectionView})
    @tool.activate()

Curve.SvgDocument = SvgDocument
