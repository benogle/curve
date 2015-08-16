SVGDocument = require '../src/svg-document'

Node = require '../src/node'
Path = require '../src/path'
SelectionModel = require '../src/selection-model'
SelectionView = require '../src/selection-view'

describe 'SelectionView', ->
  [path, canvas, model, svgDocument] = []

  beforeEach ->
    canvas = document.createElement('div')
    jasmine.attachToDOM(canvas)
    svgDocument = new SVGDocument(canvas)

    model = svgDocument.getSelectionModel()
    selectionView = svgDocument.getSelectionView()
    path = new Path(svgDocument)
    path.addNode(new Node([50, 50], [-10, 0], [10, 0]))
    path.close()

  it 'creates nodes when PREselecting and cleans up when selecting nothing', ->
    expect(canvas.querySelectorAll('svg path.object-preselection')).toHaveLength 0

    model.setPreselected(path)
    expect(canvas.querySelectorAll('svg path.object-preselection')).toHaveLength 1

    model.clearPreselected()
    expect(canvas.querySelectorAll('svg path.object-preselection')).toHaveLength 0
