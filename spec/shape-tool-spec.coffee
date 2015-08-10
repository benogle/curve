SVGDocument = require '../src/svg-document'

ShapeTool = require '../src/shape-tool'
SelectionModel = require '../src/selection-model'
Size = require '../src/size'
Point = require '../src/point'
Rectangle = require '../src/rectangle'

describe 'ShapeTool', ->
  [tool, svg, canvas, selectionModel] = []

  beforeEach ->
    canvas = document.createElement('canvas')
    jasmine.attachToDOM(canvas)
    svg = new SVGDocument(canvas)
    selectionModel = svg.getSelectionModel()
    tool = new ShapeTool(svg)

  it "has a crosshair cursor when activated", ->
    expect(svg.getSVGRoot().node.style.cursor).toBe ''
    tool.activate('rectangle')
    expect(svg.getSVGRoot().node.style.cursor).toBe 'crosshair'
    tool.deactivate()
    expect(svg.getSVGRoot().node.style.cursor).toBe ''

  it "emits a `cancel` event when clicking without creating a shape", ->
    tool.on 'cancel', cancelSpy = jasmine.createSpy()

    tool.activate()
    svgNode = svg.getSVGRoot().node
    svgNode.dispatchEvent(jasmine.buildMouseEvent('mousedown', getMouseParams(20, 30)))
    svgNode.dispatchEvent(jasmine.buildMouseEvent('mouseup'))

    expect(cancelSpy).toHaveBeenCalled()

  describe "when activated with Rectangle", ->
    beforeEach ->
      tool.activate('rectangle')
      expect(selectionModel.getSelected()).toBe null

    it "does not create an object unless dragging for >= 5px", ->
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousedown', getMouseParams(20, 30)))
      selected = selectionModel.getSelected()
      expect(selected).toBe null

      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', getMouseParams(21, 34)))
      selected = selectionModel.getSelected()
      expect(selected).toBe null

      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', getMouseParams(21, 36)))
      selected = selectionModel.getSelected()
      expect(selected).not.toBe null

    it "creates a rectangle when dragging", ->
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousedown', getMouseParams(20, 30)))
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', getMouseParams(30, 50)))
      selected = selectionModel.getSelected()
      expect(selected instanceof Rectangle).toBe true
      expect(selected.getPosition()).toEqual new Point(20, 30)
      expect(selected.getSize()).toEqual new Size(10, 20)

      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', getMouseParams(10, 50)))
      expect(selected.getPosition()).toEqual new Point(10, 30)
      expect(selected.getSize()).toEqual new Size(10, 20)

      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', getMouseParams(10, 10)))
      expect(selected.getPosition()).toEqual new Point(10, 10)
      expect(selected.getSize()).toEqual new Size(10, 20)

      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', getMouseParams(30, 10)))
      expect(selected.getPosition()).toEqual new Point(20, 10)
      expect(selected.getSize()).toEqual new Size(10, 20)

      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mouseup'))

      # mousemove events dont change it after the mouse up
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', getMouseParams(200, 150)))
      expect(selected.getPosition()).toEqual new Point(20, 10)
      expect(selected.getSize()).toEqual new Size(10, 20)

    it "constrains the proportion to 1:1 when shift is held down", ->
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousedown', getMouseParams(0, 0)))
      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mousemove', getMouseParams(30, 50), shiftKey: true))
      selected = selectionModel.getSelected()
      expect(selected.getSize()).toEqual new Size(30, 30)

      svg.getSVGRoot().node.dispatchEvent(jasmine.buildMouseEvent('mouseup'))

getMouseParams = (x, y) ->
  {
    pageX: x
    pageY: y
    offsetX: x
    offsetY: y
  }
