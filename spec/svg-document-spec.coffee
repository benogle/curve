SVGDocument = require '../src/svg-document'
Rectangle = require '../src/rectangle'
Size = require '../src/size'
Point = require '../src/point'

describe 'Curve.SVGDocument', ->
  [svg, canvas] = []
  beforeEach ->
    canvas = document.createElement('canvas')
    jasmine.attachToDOM(canvas)
    svg = new SVGDocument(canvas)

  it 'has a tool layer', ->
    expect(canvas.querySelector('svg>.tool-layer')).toBeDefined()

  describe 'when the document is empty', ->
    it "creates a new object layer with a default size", ->
      rect = new Rectangle(svg, {x: 20, y: 30, width: 45, height: 55})
      children = svg.getObjectLayer().node.childNodes
      expect(children.length).toBe 1
      expect(children[0].nodeName).toBe 'rect'

      expect(svg.getObjectLayer().width()).toBe 1024
      expect(svg.getObjectLayer().height()).toBe 1024

  describe 'reading svg', ->
    beforeEach ->

    it 'will deserialize an svg document', ->
      svg.deserialize(DOCUMENT)

      expect(canvas.querySelector('svg>svg')).toBeDefined()
      expect(canvas.querySelector('svg>svg #arrow')).toBeDefined()

    it 'places tool things in the tool layer', ->
      svg.deserialize(DOCUMENT)

      object = svg.getObjects()[0]
      svg.selectionModel.setSelected(object)
      svg.selectionModel.setSelectedNode(object.getSubpaths()[0].nodes[0])

      expect(canvas.querySelector('.tool-layer .node-editor-node')).toBeDefined()
      expect(canvas.querySelector('.tool-layer .object-selection')).toBeDefined()

  describe 'exporting svg', ->
    it 'will export an svg document', ->
      svg.deserialize(DOCUMENT)
      expect(svg.serialize().trim()).toEqual DOCUMENT_WITH_XML_DOCTYPE

    it 'serializing and deserializing is symmetrical', ->
      svg.deserialize(DOCUMENT_WITH_XML_DOCTYPE)
      expect(svg.serialize().trim()).toEqual DOCUMENT_WITH_XML_DOCTYPE

  describe 'document size', ->
    beforeEach ->
      svg.deserialize(DOCUMENT)

    it "initially has the width and height", ->
      expect(svg.getSize()).toEqual new Size(1024, 1024)

    it "sets height and width on the document when changed", ->
      svg.on 'change:size', sizeChangeSpy = jasmine.createSpy()

      svg.setSize(Size.create(1000, 1050))
      root = svg.getObjectLayer()
      expect(root.width()).toBe 1000
      expect(root.height()).toBe 1050

      expect(sizeChangeSpy).toHaveBeenCalled()

      size = sizeChangeSpy.calls.mostRecent().args[0].size
      expect(svg.getSize()).toEqual new Size(1000, 1050)

  describe "changes in the document", ->
    beforeEach ->
      svg.deserialize(DOCUMENT)

    it "emits a change event when anything in the document changes", ->
      svg.on 'change', documentChangeSpy = jasmine.createSpy()

      object = svg.getObjects()[0]
      node = object.getSubpaths()[0].nodes[0]
      node.setPoint(new Point(200, 250))

      expect(documentChangeSpy).toHaveBeenCalled()

    it "emits a change event when a new object is added and then removed", ->
      svg.on 'change', documentChangeSpy = jasmine.createSpy()

      object = new Rectangle(svg, {width: 10, height: 35})
      expect(documentChangeSpy).toHaveBeenCalled()
      expect(svg.getObjects()).toContain object

      documentChangeSpy.calls.reset()
      object.remove()
      expect(documentChangeSpy).toHaveBeenCalled()
      expect(svg.getObjects()).not.toContain object

  describe "changing tools", ->
    [pointerTool, shapeTool] = []
    beforeEach ->
      svg.initializeTools()
      shapeTool = svg.toolForType('shape')
      pointerTool = svg.toolForType('pointer')

      spyOn(pointerTool, 'activate').and.callThrough()
      spyOn(pointerTool, 'deactivate').and.callThrough()
      spyOn(shapeTool, 'activate').and.callThrough()
      spyOn(shapeTool, 'deactivate').and.callThrough()

    it "can switch to different tools", ->
      svg.on 'change:tool', toolChangeSpy = jasmine.createSpy()

      expect(svg.getActiveToolType()).toBe 'pointer'

      svg.setActiveToolType('rectangle')
      expect(toolChangeSpy).toHaveBeenCalledWith(toolType: 'rectangle')
      expect(pointerTool.activate).not.toHaveBeenCalled()
      expect(pointerTool.deactivate).toHaveBeenCalled()
      expect(shapeTool.activate).toHaveBeenCalledWith('rectangle')
      expect(shapeTool.deactivate).not.toHaveBeenCalled()
      expect(svg.getActiveToolType()).toBe 'rectangle'

      shapeTool.activate.calls.reset()
      pointerTool.deactivate.calls.reset()
      toolChangeSpy.calls.reset()
      svg.setActiveToolType('pointer')
      expect(toolChangeSpy).toHaveBeenCalledWith(toolType: 'pointer')
      expect(pointerTool.activate).toHaveBeenCalled()
      expect(pointerTool.deactivate).not.toHaveBeenCalled()
      expect(shapeTool.activate).not.toHaveBeenCalled()
      expect(shapeTool.deactivate).toHaveBeenCalled()
      expect(svg.getActiveToolType()).toBe 'pointer'

    it "will not switch to non-existent tools", ->
      svg.setActiveToolType('junk')
      expect(svg.getActiveToolType()).toBe 'pointer'
      expect(pointerTool.deactivate).not.toHaveBeenCalled()

    it "will not call deactivate when attempting to switch to the same", ->
      svg.setActiveToolType('pointer')
      expect(svg.getActiveToolType()).toBe 'pointer'
      expect(pointerTool.deactivate).not.toHaveBeenCalled()

  describe '::translateSelectedObjects', ->
    [object] = []
    beforeEach ->
      object = new Rectangle(svg, {x: 20, y: 30})

    it "does nothing when there is no selected object", ->
      svg.translateSelectedObjects([10, 0])

    it "translates the selected object by the point specified", ->
      expect(object.getPosition()).toEqual new Point(20, 30)

      svg.selectionModel.setSelected(object)
      svg.translateSelectedObjects([20, 0])

      expect(object.getPosition()).toEqual new Point(40, 30)

  describe '::removeSelectedObjects', ->
    [object] = []
    beforeEach ->
      object = new Rectangle(svg, {x: 20, y: 30})

    it "does nothing when there is no selected object", ->
      svg.removeSelectedObjects()

    it "removes the selected objects", ->
      expect(svg.getObjects()).toContain object
      svg.selectionModel.setSelected(object)
      svg.removeSelectedObjects()
      expect(svg.getObjects()).not.toContain object

DOCUMENT = '''
  <svg height="1024" width="1024" xmlns="http://www.w3.org/2000/svg">
    <path id="arrow" d="M512,384L320,576h128v320h128V576h128L512,384z"/>
  </svg>
  '''

DOCUMENT_WITH_XML_DOCTYPE = '''
  <?xml version="1.0" encoding="UTF-8"?>
  <svg style="overflow: visible;" height="1024" width="1024" xmlns="http://www.w3.org/2000/svg">
    <desc>Created with Curve</desc>
    <path d="M512,384L320,576H448V896H576V576H704Z" id="arrow">
    </path>
  </svg>
  '''
