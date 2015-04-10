describe 'Curve.SvgDocument', ->
  svg = null
  beforeEach ->
    loadFixtures 'canvas.html'
    svg = new Curve.SvgDocument($('#canvas')[0])

  it 'has a tool layer', ->
    expect($('#canvas svg>.tool-layer')).toExist()

  describe 'reading svg', ->
    beforeEach ->

    it 'will deserialize an svg document', ->
      svg.deserialize(DOCUMENT)

      expect($('#canvas svg>svg')).toExist()
      expect($('#canvas svg>svg #arrow')).toExist()

    it 'places tool things in the tool layer', ->
      svg.deserialize(DOCUMENT)

      svg.objects[0]
      svg.selectionModel.setSelected(svg.objects[0])
      svg.selectionModel.setSelectedNode(svg.objects[0].subpaths[0].nodes[0])

      expect($('#canvas .tool-layer .node-editor-node')).toExist()
      expect($('#canvas .tool-layer .object-selection')).toExist()

  describe 'exporting svg', ->
    beforeEach ->

    it 'will export an svg document', ->
      svg.deserialize(DOCUMENT)
      expect(svg.serialize().trim()).toEqual DOCUMENT_WITH_XML_DOCTYPE

    it 'serializing and deserializing is symmetrical', ->
      svg.deserialize(DOCUMENT_WITH_XML_DOCTYPE)
      expect(svg.serialize().trim()).toEqual DOCUMENT_WITH_XML_DOCTYPE

DOCUMENT = '''
  <svg height="1024" width="1024" xmlns="http://www.w3.org/2000/svg">
    <path id="arrow" d="M512,384L320,576h128v320h128V576h128L512,384z"/>
  </svg>
  '''

DOCUMENT_WITH_XML_DOCTYPE = '''
  <?xml version="1.0" encoding="UTF-8"?>
  <svg height="1024" width="1024" xmlns="http://www.w3.org/2000/svg" style="overflow:visible;">
    <desc>Created with Curve</desc>
    <path d="M512,384L320,576h128v320h128V576h128L512,384z" id="arrow">
    </path>
  </svg>
  '''

DOCUMENT_NO_ARROW = '''
  <svg height="1024" width="1024" xmlns="http://www.w3.org/2000/svg">
    <path id="not-an-arrow" d="M512,384L320,576h128v320h128V576h128L512,384z"/>
  </svg>
  '''
