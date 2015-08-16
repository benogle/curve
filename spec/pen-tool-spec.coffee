SVGDocument = require '../src/svg-document'

PenTool = require '../src/pen-tool'
Size = require '../src/size'
Point = require '../src/point'
Path = require '../src/path'

describe 'PenTool', ->
  [tool, svg, canvas, selectionModel] = []

  beforeEach ->
    canvas = document.createElement('canvas')
    jasmine.attachToDOM(canvas)
    svg = new SVGDocument(canvas)
    selectionModel = svg.getSelectionModel()
    tool = new PenTool(svg)

  describe "when activated", ->
    beforeEach ->
      tool.activate()
      expect(selectionModel.getSelected()).toBe null

    it "creates a path when dragging", ->
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousedown', getMouseParams(20, 30)))
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', getMouseParams(30, 50)))
      selected = selectionModel.getSelected()
      selectedNode = selectionModel.getSelectedNode()
      expect(selected instanceof Path).toBe true
      expect(selectedNode).toBe selected.getNodes()[0]
      expect(selectedNode.getPoint()).toEqual new Point(20, 30)
      expect(selectedNode.getHandleIn()).toEqual new Point(-10, -20)
      expect(selectedNode.getHandleOut()).toEqual new Point(10, 20)
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mouseup'))

      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousedown', getMouseParams(80, 90)))
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', getMouseParams(50, 100)))
      selectedNode = selectionModel.getSelectedNode()
      expect(selected instanceof Path).toBe true
      expect(selectedNode).toBe selected.getNodes()[1]
      expect(selectedNode.getPoint()).toEqual new Point(80, 90)
      expect(selectedNode.getHandleIn()).toEqual new Point(30, -10)
      expect(selectedNode.getHandleOut()).toEqual new Point(-30, 10)
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mouseup'))

    it "closes the path when clicking on the first node", ->

getMouseParams = (x, y) ->
  {
    pageX: x
    pageY: y
    offsetX: x
    offsetY: y
  }
