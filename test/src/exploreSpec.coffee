describe 'Curve.Path', ->
  beforeEach ->
    loadFixtures 'canvas.html'
    window.raphael = Raphael("canvas")

  it 'can be created', ->
    path = new Curve.Path()
    path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
    path.addNode(new Curve.Node([80, 60], [-10, -5], [10, 5]))
    path.addNode(new Curve.Node([60, 80], [10, 0], [-10, 0]))
    path.close()

    el = $('svg path')
    expect(el.attr('d')).toMatch(/^M50,50C60,50/)
    expect(el.attr('d')).toMatch(/Z$/)

  it 'is associated with the node', ->
    path = new Curve.Path(@raphael)
    path.addNode(new Curve.Node([60, 80], [10, 0], [-10, 0]))
    path.render()

    el = $('svg path')
    expect(Curve.getObjectFromNode(el[0])).toEqual path

  describe 'updating', ->
    beforeEach ->
      @path = new Curve.Path()
      @path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
      @path.addNode(new Curve.Node([80, 60], [-10, -5], [10, 5]))
      @path.addNode(new Curve.Node([60, 80], [10, 0], [-10, 0]))
      @path.close()

    it 'renders when node point is updated', ->
      @path.nodes[0].setPoint([70, 70])
      el = $('svg path')
      expect(el.attr('d')).toMatch(/^M70,70C80,70/)

    it 'kicks out event when changes', ->
      spy = jasmine.createSpy()
      @path.on 'change', spy

      @path.nodes[0].setPoint([70, 70])

      expect(spy).toHaveBeenCalled()
      expect(spy.mostRecentCall.args[1]).toEqual
        event: 'change:point',
        index: 0
        old: new Curve.Point(50, 50)
        value: new Curve.Point(70, 70)


describe 'Curve.SelectionModel', ->
  beforeEach ->
    @s = new Curve.SelectionModel()
    @path = {id: 1}

    @s.on 'change:selected', @onSelected = jasmine.createSpy()
    @s.on 'change:selectedNode', @onSelectedNode = jasmine.createSpy()

  it 'fires events when changing selection', ->
    @s.setSelected(@path)

    expect(@onSelected).toHaveBeenCalled()
    expect(@onSelected.mostRecentCall.args[0]).toEqual object: @path, old: null

  it 'fires events when changing selected node', ->
    node = {omg: 1}
    @s.setSelectedNode(node)

    expect(@onSelectedNode).toHaveBeenCalled()
    expect(@onSelectedNode.mostRecentCall.args[0]).toEqual node: node, old: null

  it 'sends proper old value through when unset', ->
    node = {omg: 1}
    @s.setSelectedNode(node)
    @s.setSelectedNode(null)

    expect(@onSelectedNode).toHaveBeenCalled()
    expect(@onSelectedNode.mostRecentCall.args[0]).toEqual node: null, old: node

describe 'Curve.SelectionView', ->
  beforeEach ->
    loadFixtures 'canvas.html'
    window.raphael = Raphael("canvas")

  beforeEach ->
    @model = new Curve.SelectionModel()
    @s = new Curve.SelectionView(@model)
    @path = new Curve.Path()
    @path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
    @path.close()

  it 'creates nodes when selecting and cleans up when selecting nothing', ->
    @model.setSelected(@path)

    expect($('svg circle.node-editor-node:eq(0)')).toShow()
    expect($('svg path.object-selection').length).toEqual 1

    @model.clearSelected()

    expect($('svg circle.node-editor-node:eq(0)')).toHide()
    expect($('svg path.object-selection').length).toEqual 0

  it 'renders node editor when selecting a node', ->
    @model.setSelected(@path)
    @model.setSelectedNode(@path.nodes[0])

    expect($('svg circle.node-editor-handle:eq(0)')).toShow()
    expect($('svg circle.node-editor-handle:eq(1)')).toShow()
    expect($('svg circle.node-editor-handle:eq(0)')).toHaveAttr 'cx', 40
    expect($('svg circle.node-editor-handle:eq(1)')).toHaveAttr 'cx', 60

    @model.clearSelectedNode()

    expect($('svg circle.node-editor-handle:eq(0)')).toHide()
    expect($('svg circle.node-editor-handle:eq(1)')).toHide()

  it 'hides handles when unselecting object', ->
    @model.setSelected(@path)
    @model.setSelectedNode(@path.nodes[0])

    expect($('svg circle.node-editor-handle:eq(0)')).toShow()
    expect($('svg circle.node-editor-handle:eq(1)')).toShow()

    @model.setSelected(null)

    expect($('svg circle.node-editor-handle:eq(0)')).toHide()
    expect($('svg circle.node-editor-handle:eq(1)')).toHide()
