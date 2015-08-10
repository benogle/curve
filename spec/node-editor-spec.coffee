SVGDocument = require '../src/svg-document'

Node = require '../src/node'
Path = require '../src/path'
Point = require '../src/point'
NodeEditor = require '../src/node-editor'

describe 'NodeEditor', ->
  [svgDocument, path, nodeEditor] = []
  beforeEach ->
    canvas = document.createElement('canvas')
    jasmine.attachToDOM(canvas)
    svgDocument = new SVGDocument(canvas)

    path = new Path(svgDocument)
    path.addNode(new Node([50, 50], [-10, 0], [10, 0]))
    path.addNode(new Node([80, 60], [-10, -5], [10, 5]))
    path.addNode(new Node([60, 80], [10, 0], [-10, 0]))
    path.close()

    nodeEditor = new NodeEditor(svgDocument)

  describe 'dragging handles', ->
    beforeEach ->
      nodeEditor.setNode(path.getSubpaths()[0].nodes[0])

    it 'dragging a handle updates the path and the node editor', ->
      nodeEditor._startPosition = path.getSubpaths()[0].nodes[0].getPoint()
      nodeEditor.onDraggingHandleOut({x: 20, y: 10}, {clientX: 70, clientY: 60})

      expect(path.getSubpaths()[0].nodes[0].handleOut).toEqual new Point([20, 10])
      expect(nodeEditor.handleElements.members[1].node).toHaveAttr 'cx', '70'
      expect(nodeEditor.handleElements.members[1].node).toHaveAttr 'cy', '60'
