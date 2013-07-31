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