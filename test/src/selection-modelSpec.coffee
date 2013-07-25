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
