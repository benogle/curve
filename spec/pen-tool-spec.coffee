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

    it "creates a path when clicking and dragging", ->
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousedown', jasmine.buildMouseParams(20, 30)))
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', jasmine.buildMouseParams(30, 50)))
      selected = selectionModel.getSelected()
      selectedNode = selectionModel.getSelectedNode()
      expect(selected instanceof Path).toBe true
      expect(selectedNode).toBe selected.getNodes()[0]
      expect(selectedNode.getPoint()).toEqual new Point(20, 30)
      expect(selectedNode.getHandleIn()).toEqual new Point(-10, -20)
      expect(selectedNode.getHandleOut()).toEqual new Point(10, 20)
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mouseup'))

      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousedown', jasmine.buildMouseParams(80, 90)))
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', jasmine.buildMouseParams(50, 100)))
      selectedNode = selectionModel.getSelectedNode()
      expect(selected instanceof Path).toBe true
      expect(selectedNode).toBe selected.getNodes()[1]
      expect(selectedNode.getPoint()).toEqual new Point(80, 90)
      expect(selectedNode.getHandleIn()).toEqual new Point(30, -10)
      expect(selectedNode.getHandleOut()).toEqual new Point(-30, 10)
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mouseup'))

      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousedown', jasmine.buildMouseParams(85, 95)))
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', jasmine.buildMouseParams(55, 105)))
      selectedNode = selectionModel.getSelectedNode()
      expect(selected instanceof Path).toBe true
      expect(selectedNode).toBe selected.getNodes()[2]
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mouseup'))

      # remove the node, it selects the previous
      selected.removeNode(selected.getNodes()[2])
      selectedNode = selectionModel.getSelectedNode()
      expect(selectedNode).toBe selected.getNodes()[1]

      # closes when clicking on the first node
      nodeEditorElement = svg.getObjectEditor().getActiveEditor().nodeEditors[0].nodeElement.node
      xyParams = jasmine.buildMouseParams(20, 30)
      nodeEditorElement.dispatchEvent(jasmine.buildMouseEvent('mousedown', xyParams, target: nodeEditorElement))

      selectedNode = selectionModel.getSelectedNode()
      expect(selected.isClosed()).toBe true
      expect(selectedNode).toBe selected.getNodes()[0]
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mouseup'))

      # now it should create a new Path
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousedown', jasmine.buildMouseParams(200, 300)))
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', jasmine.buildMouseParams(300, 500)))
      newSelected = selectionModel.getSelected()
      newSelectedNode = selectionModel.getSelectedNode()
      expect(newSelected instanceof Path).toBe true
      expect(newSelected).not.toBe selected
      expect(newSelectedNode).toBe newSelected.getNodes()[0]
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mouseup'))
