describe 'Curve.Path', ->
  beforeEach ->
    loadFixtures 'canvas.html'
    window.svg = SVG("canvas")

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
    path = new Curve.Path()
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

    it 'kicks out event when closed', ->
      closespy = jasmine.createSpy()
      changespy = jasmine.createSpy()
      @path.on 'close', closespy
      @path.on 'change', changespy

      @path.close()

      expect(closespy).toHaveBeenCalled()
      expect(changespy).toHaveBeenCalled()

    it 'node added adds node to the end', ->
      node = new Curve.Node([40, 60], [0, 0], [0, 0])

      spy = jasmine.createSpy()
      @path.on 'insert:node', spy

      @path.addNode(node)

      expect(@path.nodes[3]).toEqual node
      expect(spy.mostRecentCall.args[1]).toEqual
        event: 'insert:node',
        index: 3
        value: node

    it 'node inserted inserts node in right place', ->
      node = new Curve.Node([40, 60], [0, 0], [0, 0])

      spy = jasmine.createSpy()
      @path.on 'insert:node', spy

      @path.insertNode(node, 0)

      expect(@path.nodes[0]).toEqual node
      expect(spy.mostRecentCall.args[1]).toEqual
        event: 'insert:node',
        index: 0
        value: node


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
    window.svg = SVG("canvas")

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

  it 'creates nodes when PREselecting and cleans up when selecting nothing', ->
    @model.setPreselected(@path)

    expect($('svg circle.node-editor-node').length).toEqual 0
    expect($('svg path.object-preselection').length).toEqual 1

    @model.clearPreselected()

    expect($('svg path.object-preselection').length).toEqual 0

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

describe 'Curve.Node', ->
  beforeEach ->
    @s = new Curve.Node([50, 50], [-10, 0], [10, 0])

  describe 'joined handles', ->
    it 'updating one handle updates the other', ->
      @s.setHandleIn([20, 30])
      expect(@s.handleOut).toEqual new Curve.Point(-20, -30)

      @s.setHandleOut([15, -5])
      expect(@s.handleIn).toEqual new Curve.Point(-15, 5)

describe 'Curve.NodeEditor', ->
  beforeEach ->
    loadFixtures 'canvas.html'
    window.svg = SVG("canvas")

    @path = new Curve.Path()
    @path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
    @path.addNode(new Curve.Node([80, 60], [-10, -5], [10, 5]))
    @path.addNode(new Curve.Node([60, 80], [10, 0], [-10, 0]))
    @path.close()

    @model = new Curve.SelectionModel()
    @s = new Curve.NodeEditor()

  describe 'dragging handles', ->
    beforeEach ->
      @s.setNode(@path.nodes[0])

    it 'dragging a handle updates the path and the node editor', ->
      @s.onDraggingHandleOut({x:10, y:10}, {clientX: 70, clientY: 60})

      expect(@path.nodes[0].handleOut).toEqual new Curve.Point([20, 10])
      expect($(@s.handleElements.members[1].node)).toHaveAttr 'cx', 70
      expect($(@s.handleElements.members[1].node)).toHaveAttr 'cy', 60
