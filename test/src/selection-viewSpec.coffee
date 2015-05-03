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

  it 'creates object-selection when selecting and cleans up when selecting nothing', ->
    @model.setSelected(@path)
    expect($('svg path.object-selection').length).toEqual 1

    @model.clearSelected()
    expect($('svg path.object-selection').length).toEqual 0

  it 'creates nodes when PREselecting and cleans up when selecting nothing', ->
    expect($('svg path.object-preselection').length).toEqual 0

    @model.setPreselected(@path)
    expect($('svg path.object-preselection').length).toEqual 1

    @model.clearPreselected()
    expect($('svg path.object-preselection').length).toEqual 0
