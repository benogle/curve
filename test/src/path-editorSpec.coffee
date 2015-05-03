describe 'Curve.PathEditor', ->
  svg = null
  beforeEach ->
    loadFixtures 'canvas.html'
    svg = SVG("canvas")

  beforeEach ->
    @editor = new Curve.PathEditor(svg)
    @path = new Curve.Path(svg)
    @path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
    @path.close()

  it 'creates nodes when selecting and cleans up when selecting nothing', ->
    @editor.activateObject(@path)

    expect($('svg circle.node-editor-node:eq(0)')).toShow()

    @editor.deactivate()

    expect($('svg circle.node-editor-node:eq(0)')).toHide()

  it 'renders node editor when selecting a node', ->
    @editor.activateObject(@path)
    @editor.activateNode(@path.getSubpaths()[0].nodes[0])

    expect($('svg circle.node-editor-handle:eq(0)')).toShow()
    expect($('svg circle.node-editor-handle:eq(1)')).toShow()
    expect($('svg circle.node-editor-handle:eq(0)')).toHaveAttr 'cx', 40
    expect($('svg circle.node-editor-handle:eq(1)')).toHaveAttr 'cx', 60

    @editor.deactivateNode()

    expect($('svg circle.node-editor-handle:eq(0)')).toHide()
    expect($('svg circle.node-editor-handle:eq(1)')).toHide()

  it 'hides handles when unselecting object', ->
    @editor.activateObject(@path)
    @editor.activateNode(@path.getSubpaths()[0].nodes[0])

    expect($('svg circle.node-editor-handle:eq(0)')).toShow()
    expect($('svg circle.node-editor-handle:eq(1)')).toShow()

    @editor.deactivate()

    expect($('svg circle.node-editor-handle:eq(0)')).toHide()
    expect($('svg circle.node-editor-handle:eq(1)')).toHide()

  it 'makes new NodeEditors when adding nodes to object', ->
    @editor.activateObject(@path)

    expect($('svg circle.node-editor-node').length).toEqual 1

    @path.addNode(new Curve.Node([40, 40], [-10, 0], [10, 0]))
    expect($('svg circle.node-editor-node').length).toEqual 2

    @path.addNode(new Curve.Node([10, 40], [-10, 0], [10, 0]))
    expect($('svg circle.node-editor-node').length).toEqual 3
