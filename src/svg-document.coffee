SVG = window.SVG or require('./vendor/svg').SVG

class SvgDocument
  constructor: (rootNode) ->
    @objects = []
    @svgDocument = SVG(rootNode)

    @toolLayer = @svgDocument.group()
    @toolLayer.node.setAttribute('class', 'tool-layer')

    @selectionModel = new Curve.SelectionModel()
    @selectionView = new Curve.SelectionView(@toolLayer, @selectionModel)

    @tool = new Curve.PointerTool(@svgDocument, {@selectionModel, @selectionView})
    @tool.activate()

  import: (svgString) ->
    @objects = Curve.import(@svgDocument, svgString)
    @toolLayer.front()

Curve.SvgDocument = SvgDocument
