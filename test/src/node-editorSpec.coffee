describe 'Curve.NodeEditor', ->
  beforeEach ->
    loadFixtures 'canvas.html'
    svg = SVG("canvas")

    @path = new Curve.Path(svg)
    @path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
    @path.addNode(new Curve.Node([80, 60], [-10, -5], [10, 5]))
    @path.addNode(new Curve.Node([60, 80], [10, 0], [-10, 0]))
    @path.close()

    @model = new Curve.SelectionModel()
    @s = new Curve.NodeEditor(svg)

  describe 'dragging handles', ->
    beforeEach ->
      @s.setNode(@path.getSubpaths()[0].nodes[0])

    it 'dragging a handle updates the path and the node editor', ->
      spyOn($.fn, 'offset').andReturn top: 0, left: 0
      @s.onDraggingHandleOut({x:10, y:10}, {clientX: 70, clientY: 60})

      expect(@path.getSubpaths()[0].nodes[0].handleOut).toEqual new Curve.Point([20, 10])
      expect($(@s.handleElements.members[1].node)).toHaveAttr 'cx', 70
      expect($(@s.handleElements.members[1].node)).toHaveAttr 'cy', 60
