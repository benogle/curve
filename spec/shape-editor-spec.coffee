SVGDocument = require '../src/svg-document'
Node = require '../src/node'
Rectangle = require '../src/Rectangle'
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
      object = new Rectangle(svgDocument)

    it 'creates nodes when selecting and cleans up when selecting nothing', ->
      editor.activateObject(object)
      expect(canvas.querySelectorAll('svg rect.shape-editor-handle')[0]).toShow()

      editor.deactivate()
      expect(canvas.querySelectorAll('svg rect.shape-editor-handle')[0]).toHide()
