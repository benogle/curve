SVGDocument = require '../src/svg-document'
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
      root = svg.getSvgRoot()
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

  describe "changing tools", ->
    beforeEach ->
      spyOn(svg.tools.pointer, 'activate').and.callThrough()
      spyOn(svg.tools.pointer, 'deactivate').and.callThrough()
      spyOn(svg.tools.shape, 'activate').and.callThrough()
      spyOn(svg.tools.shape, 'deactivate').and.callThrough()

    it "can switch to different tools", ->
      expect(svg.getActiveToolType()).toBe 'pointer'

      svg.setActiveToolType('rectangle')
      expect(svg.tools.pointer.activate).not.toHaveBeenCalled()
      expect(svg.tools.pointer.deactivate).toHaveBeenCalled()
      expect(svg.tools.shape.activate).toHaveBeenCalledWith('rectangle')
      expect(svg.tools.shape.deactivate).not.toHaveBeenCalled()
      expect(svg.getActiveToolType()).toBe 'rectangle'

      svg.tools.shape.activate.calls.reset()
      svg.tools.pointer.deactivate.calls.reset()
      svg.setActiveToolType('pointer')
      expect(svg.tools.pointer.activate).toHaveBeenCalled()
      expect(svg.tools.pointer.deactivate).not.toHaveBeenCalled()
      expect(svg.tools.shape.activate).not.toHaveBeenCalled()
      expect(svg.tools.shape.deactivate).toHaveBeenCalled()
      expect(svg.getActiveToolType()).toBe 'pointer'

    it "will not switch to non-existent tools", ->
      svg.setActiveToolType('junk')
      expect(svg.getActiveToolType()).toBe 'pointer'
      expect(svg.tools.pointer.deactivate).not.toHaveBeenCalled()

  describe '::translateSelectedObjects', ->
    beforeEach ->
      svg.deserialize('<svg height="1024" width="1024" xmlns="http://www.w3.org/2000/svg"><rect x="20" y="30" width="200" height="400" fill="red"/></svg>')

    it "does nothing when there is no selected object", ->
      svg.translateSelectedObjects([10, 0])

    it "translates the selected object by the point specified", ->
      object = svg.getObjects()[0]
      expect(object.getPosition()).toEqual new Point(20, 30)

      svg.selectionModel.setSelected(object)
      svg.translateSelectedObjects([20, 0])

      expect(object.getPosition()).toEqual new Point(40, 30)

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
