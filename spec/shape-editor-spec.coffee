SVGDocument = require '../src/svg-document'
Node = require '../src/node'
Rectangle = require '../src/rectangle'
Point = require '../src/point'
Size = require '../src/size'
ShapeEditor = require '../src/shape-editor'

describe 'ShapeEditor', ->
  [svgDocument, canvas, object, editor] = []
  beforeEach ->
    canvas = document.createElement('div')
    jasmine.attachToDOM(canvas)
    svgDocument = new SVGDocument(canvas)

  describe "when using a Rectangle object", ->
    beforeEach ->
      editor = new ShapeEditor(svgDocument)
      object = new Rectangle(svgDocument, x: 20, y: 20, width: 100, height: 200)
      editor.activateObject(object)

    it 'creates nodes when selecting and cleans up when selecting nothing', ->
      expect(canvas.querySelectorAll('svg rect.shape-editor-handle')[0]).toShow()

      editor.deactivate()
      expect(canvas.querySelectorAll('svg rect.shape-editor-handle')[0]).toHide()

    it "updates the object and the handles when dragging the Top Left handles", ->
      cornerHandle = editor.cornerHandles.members[0]
      cornerHandleNode = cornerHandle.node
      xyParams = jasmine.buildMouseParams(20, 20)
      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mousedown', xyParams, target: cornerHandleNode))

      xyParams = jasmine.buildMouseParams(10, 15)
      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mousemove', xyParams, target: cornerHandleNode))
      expect(object.get('position')).toEqual new Point(10, 15)
      expect(object.get('size')).toEqual new Size(110, 205)
      expect(cornerHandle.attr('x')).toBe 10 - editor.handleSize / 2
      expect(cornerHandle.attr('y')).toBe 15 - editor.handleSize / 2

      xyParams = jasmine.buildMouseParams(200, 300)
      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mousemove', xyParams, target: cornerHandleNode))
      expect(object.get('position')).toEqual new Point(120, 220)
      expect(object.get('size')).toEqual new Size(80, 80)
      expect(cornerHandle.attr('x')).toBe 120 - editor.handleSize / 2
      expect(cornerHandle.attr('y')).toBe 220 - editor.handleSize / 2

      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mouseup', xyParams))

    it "updates the object and the handles when dragging the Top Right handles", ->
      # Top right
      cornerHandle = editor.cornerHandles.members[1]
      cornerHandleNode = cornerHandle.node
      xyParams = jasmine.buildMouseParams(120, 20)
      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mousedown', xyParams, target: cornerHandleNode))

      xyParams = jasmine.buildMouseParams(130, 10)
      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mousemove', xyParams, target: cornerHandleNode))
      expect(object.get('position')).toEqual new Point(20, 10)
      expect(object.get('size')).toEqual new Size(110, 210)
      expect(cornerHandle.attr('x')).toBe 130 - editor.handleSize / 2
      expect(cornerHandle.attr('y')).toBe 10 - editor.handleSize / 2

      xyParams = jasmine.buildMouseParams(0, 230)
      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mousemove', xyParams, target: cornerHandleNode))
      expect(object.get('position')).toEqual new Point(0, 220)
      expect(object.get('size')).toEqual new Size(20, 10)
      expect(cornerHandle.attr('x')).toBe 20 - editor.handleSize / 2
      expect(cornerHandle.attr('y')).toBe 220 - editor.handleSize / 2

      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mouseup', xyParams))

    it "constrains to 1:1 proportion when shift is held while dragging", ->
      # bottom right
      cornerHandle = editor.cornerHandles.members[2]
      cornerHandleNode = cornerHandle.node
      xyParams = jasmine.buildMouseParams(120, 220)
      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mousedown', xyParams, target: cornerHandleNode))

      xyParams = jasmine.buildMouseParams(100, 300)
      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mousemove', xyParams, target: cornerHandleNode, shiftKey: true))
      expect(object.get('position')).toEqual new Point(20, 20)
      expect(object.get('size')).toEqual new Size(80, 80)
      expect(cornerHandle.attr('x')).toBe 100 - editor.handleSize / 2
      expect(cornerHandle.attr('y')).toBe 100 - editor.handleSize / 2

      xyParams = jasmine.buildMouseParams(300, 100)
      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mousemove', xyParams, target: cornerHandleNode, shiftKey: true))
      expect(object.get('position')).toEqual new Point(20, 20)
      expect(object.get('size')).toEqual new Size(80, 80)
      expect(cornerHandle.attr('x')).toBe 100 - editor.handleSize / 2
      expect(cornerHandle.attr('y')).toBe 100 - editor.handleSize / 2

      cornerHandleNode.dispatchEvent(jasmine.buildMouseEvent('mouseup', xyParams))
