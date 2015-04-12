describe 'Curve.SelectionView', ->
  svg = null
  beforeEach ->
    loadFixtures 'canvas.html'
    svg = SVG("canvas")

  beforeEach ->
    @model = new Curve.SelectionModel()
    @s = new Curve.SelectionView(svg, @model)
    @path = new Curve.Path(svg)
    @path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
    @path.close()

  it 'creates nodes when selecting and cleans up when selecting nothing', ->
    @model.setSelected(@path)

    expect($('svg circle.node-editor-node:eq(0)')).toShow()
    expect($('svg path.object-selection').length).toEqual 1

    @model.clearSelected()

    expect($('svg circle.node-editor-node:eq(0)')).toHide()
    expect($('svg path.object-selection').length).toEqual 0

  it 'creates nodes when PREselecting and cleans up when selecting nothing', ->
    expect($('svg path.object-preselection').length).toEqual 0

    @model.setPreselected(@path)

    expect($('svg circle.node-editor-node').length).toEqual 0
    expect($('svg path.object-preselection').length).toEqual 1

    @model.clearPreselected()

    expect($('svg path.object-preselection').length).toEqual 0

  it 'renders node editor when selecting a node', ->
    @model.setSelected(@path)
    @model.setSelectedNode(@path.getSubpaths()[0].nodes[0])

    expect($('svg circle.node-editor-handle:eq(0)')).toShow()
    expect($('svg circle.node-editor-handle:eq(1)')).toShow()
    expect($('svg circle.node-editor-handle:eq(0)')).toHaveAttr 'cx', 40
    expect($('svg circle.node-editor-handle:eq(1)')).toHaveAttr 'cx', 60

    @model.clearSelectedNode()

    expect($('svg circle.node-editor-handle:eq(0)')).toHide()
    expect($('svg circle.node-editor-handle:eq(1)')).toHide()

  it 'hides handles when unselecting object', ->
    @model.setSelected(@path)
    @model.setSelectedNode(@path.getSubpaths()[0].nodes[0])

    expect($('svg circle.node-editor-handle:eq(0)')).toShow()
    expect($('svg circle.node-editor-handle:eq(1)')).toShow()

    @model.setSelected(null)

    expect($('svg circle.node-editor-handle:eq(0)')).toHide()
    expect($('svg circle.node-editor-handle:eq(1)')).toHide()

  it 'makes new NodeEditors when adding nodes to object', ->
    @model.setSelected(@path)

    expect($('svg circle.node-editor-node').length).toEqual 1

    @path.addNode(new Curve.Node([40, 40], [-10, 0], [10, 0]))
    expect($('svg circle.node-editor-node').length).toEqual 2

    @path.addNode(new Curve.Node([10, 40], [-10, 0], [10, 0]))
    expect($('svg circle.node-editor-node').length).toEqual 3
