SVGDocument = require '../src/svg-document'

Node = require '../src/node'
Path = require '../src/path'
Rectangle = require '../src/rectangle'
Ellipse = require '../src/ellipse'
SelectionModel = require '../src/selection-model'
ObjectEditor = require '../src/object-editor'
ShapeEditor = require '../src/shape-editor'

describe 'ObjectEditor', ->
  [canvas, svgDocument, model, editor, path] = []
  beforeEach ->
    canvas = document.createElement('div')
    jasmine.attachToDOM(canvas)
    svgDocument = new SVGDocument(canvas)
    model = svgDocument.getSelectionModel()

    editor = new ObjectEditor(svgDocument)
    path = new Path(svgDocument)
    path.addNode(new Node([50, 50], [-10, 0], [10, 0]))
    path.close()

  it 'ignores selection model when not active', ->
    expect(editor.isActive()).toBe false
    expect(editor.getActiveObject()).toBe null
    model.setSelected(path)
    expect(editor.isActive()).toBe false
    expect(editor.getActiveObject()).toBe null

  describe "when there are selected objects before the editor becomes active", ->
    beforeEach ->
      model.setSelected(path)
      model.setSelectedNode(path.getNodes()[0])

    it 'activates the editor associated with the selected object', ->
      editor.activate()
      expect(editor.isActive()).toBe true
      expect(editor.getActiveObject()).toBe path
      expect(editor.getActiveEditor().activeNode).toBe path.getNodes()[0]

  describe "when the ObjectEditor is active", ->
    beforeEach ->
      editor.activate()
      expect(editor.isActive()).toBe true
      expect(editor.getActiveObject()).toBe null

    it 'activates the editor associated with the selected object', ->
      model.setSelected(path)
      expect(editor.isActive()).toBe true
      expect(editor.getActiveObject()).toBe path
      expect(canvas.querySelector('svg circle.node-editor-node')).toShow()

      model.clearSelected()
      expect(editor.isActive()).toBe true
      expect(editor.getActiveObject()).toBe null
      expect(canvas.querySelector('svg circle.node-editor-node')).toHide()

    it 'deactivates the editor associated with the selected object when the ObjectEditor is deactivated', ->
      model.setSelected(path)
      expect(editor.isActive()).toBe true
      expect(editor.getActiveObject()).toBe path
      expect(canvas.querySelector('svg circle.node-editor-node')).toShow()

      editor.deactivate()
      expect(editor.isActive()).toBe false
      expect(editor.getActiveObject()).toBe null
      expect(canvas.querySelector('svg circle.node-editor-node')).toHide()

    describe "when the selected object is a Rectangle", ->
      [object] = []
      beforeEach ->
        object = new Rectangle(svgDocument)

      it "activates the ShapeEditor", ->
        model.setSelected(object)
        expect(editor.isActive()).toBe true
        expect(editor.getActiveObject()).toBe object
        expect(editor.getActiveEditor() instanceof ShapeEditor).toBe true

    describe "when the selected object is an Ellipse", ->
      [object] = []
      beforeEach ->
        object = new Ellipse(svgDocument)

      it "activates the ShapeEditor", ->
        model.setSelected(object)
        expect(editor.isActive()).toBe true
        expect(editor.getActiveObject()).toBe object
        expect(editor.getActiveEditor() instanceof ShapeEditor).toBe true

    describe "when the selected node is changed", ->
      it 'activates the node editor associated with the selected node', ->
        model.setSelected(path)
        expect(editor.isActive()).toBe true
        expect(editor.getActiveObject()).toBe path
        expect(editor.getActiveEditor().activeNode).toBe null

        model.setSelectedNode(path.getNodes()[0])
        expect(editor.getActiveEditor().activeNode).toBe path.getNodes()[0]

        model.setSelectedNode()
        expect(editor.getActiveEditor().activeNode).toBe null
