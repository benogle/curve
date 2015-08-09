SVG = require '../vendor/svg'

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
    svg = SVG(canvas)
    selectionModel = new SelectionModel()
    tool = new ShapeTool(svg, {selectionModel})

  it "has a crosshair cursor when activated", ->
    expect(svg.node.style.cursor).toBe ''
    tool.activate('Rectangle')
    expect(svg.node.style.cursor).toBe 'crosshair'
    tool.deactivate()
    expect(svg.node.style.cursor).toBe ''

  describe "when activated with Rectangle", ->
    beforeEach ->
      tool.activate('Rectangle')
      expect(selectionModel.getSelected()).toBe null

    it "creates a rectangle when dragging", ->
      svg.node.dispatchEvent(jasmine.buildMouseEvent('mousedown', pageX: 20, pageY: 30))
      selected = selectionModel.getSelected()
      expect(selected instanceof Rectangle).toBe true
      expect(selected.getPosition()).toEqual new Point(20, 30)
      expect(selected.getSize()).toEqual new Size(0, 0)

      svg.node.dispatchEvent(jasmine.buildMouseEvent('mousemove', pageX: 30, pageY: 50))
      expect(selected.getPosition()).toEqual new Point(20, 30)
      expect(selected.getSize()).toEqual new Size(10, 20)

      svg.node.dispatchEvent(jasmine.buildMouseEvent('mousemove', pageX: 10, pageY: 50))
      expect(selected.getPosition()).toEqual new Point(10, 30)
      expect(selected.getSize()).toEqual new Size(10, 20)

      svg.node.dispatchEvent(jasmine.buildMouseEvent('mousemove', pageX: 10, pageY: 10))
      expect(selected.getPosition()).toEqual new Point(10, 10)
      expect(selected.getSize()).toEqual new Size(10, 20)

      svg.node.dispatchEvent(jasmine.buildMouseEvent('mousemove', pageX: 30, pageY: 10))
      expect(selected.getPosition()).toEqual new Point(20, 10)
      expect(selected.getSize()).toEqual new Size(10, 20)

      svg.node.dispatchEvent(jasmine.buildMouseEvent('mouseup'))

      # mousemove events dont change it after the mouse up
      svg.node.dispatchEvent(jasmine.buildMouseEvent('mousemove', pageX: 200, pageY: 150))
      expect(selected.getPosition()).toEqual new Point(20, 10)
      expect(selected.getSize()).toEqual new Size(10, 20)

    it "constrains the proportion to 1:1 when shift is held down", ->
      svg.node.dispatchEvent(jasmine.buildMouseEvent('mousedown', pageX: 0, pageY: 0))
      selected = selectionModel.getSelected()

      svg.node.dispatchEvent(jasmine.buildMouseEvent('mousemove', pageX: 30, pageY: 50, shiftKey: true))
      expect(selected.getSize()).toEqual new Size(30, 30)

      svg.node.dispatchEvent(jasmine.buildMouseEvent('mouseup'))
