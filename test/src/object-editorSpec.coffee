describe 'Curve.ObjectEditor', ->
  svg = null
  beforeEach ->
    loadFixtures 'canvas.html'
    svg = SVG("canvas")

  beforeEach ->
    @model = new Curve.SelectionModel()
    @editor = new Curve.ObjectEditor(svg, @model)
    @path = new Curve.Path(svg)
    @path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
    @path.close()

  it 'ignores selection model when not active', ->
    expect(@editor.isActive()).toBe false
    expect(@editor.getActiveObject()).toBe null
    @model.setSelected(@path)
    expect(@editor.isActive()).toBe false
    expect(@editor.getActiveObject()).toBe null

  describe "when the ObjectEditor is active", ->
    beforeEach ->
      @editor.activate()
      expect(@editor.isActive()).toBe true
      expect(@editor.getActiveObject()).toBe null

    it 'activates the editor associated with the selected object', ->
      @model.setSelected(@path)
      expect(@editor.isActive()).toBe true
      expect(@editor.getActiveObject()).toBe @path
      expect($('svg circle.node-editor-node:eq(0)')).toShow()

      @model.clearSelected()
      expect(@editor.isActive()).toBe true
      expect(@editor.getActiveObject()).toBe null
      expect($('svg circle.node-editor-node:eq(0)')).toHide()

    it 'deactivates the editor associated with the selected object when the ObjectEditor is deactivated', ->
      @model.setSelected(@path)
      expect(@editor.isActive()).toBe true
      expect(@editor.getActiveObject()).toBe @path
      expect($('svg circle.node-editor-node:eq(0)')).toShow()

      @editor.deactivate()
      expect(@editor.isActive()).toBe false
      expect(@editor.getActiveObject()).toBe null
      expect($('svg circle.node-editor-node:eq(0)')).toHide()
