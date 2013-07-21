describe 'Curve.Path', ->
  beforeEach ->
    loadFixtures 'canvas.html'
    window.raphael = Raphael("canvas")

  it 'can be created', ->
    path = new Curve.Path()
    path.addPathPoint(new Curve.PathPoint([50, 50], [-10, 0], [10, 0]))
    path.addPathPoint(new Curve.PathPoint([80, 60], [-10, -5], [10, 5]))
    path.addPathPoint(new Curve.PathPoint([60, 80], [10, 0], [-10, 0]))
    path.close()

    el = $('svg path')
    expect(el.attr('d')).toMatch(/^M50,50C60,50/)
    expect(el.attr('d')).toMatch(/Z$/)

  it 'is associated with the node', ->
    path = new Curve.Path(@raphael)
    path.addPathPoint(new Curve.PathPoint([60, 80], [10, 0], [-10, 0]))
    path.render()

    el = $('svg path')
    expect(Curve.getObjectFromNode(el[0])).toEqual path


describe 'Curve.SelectionModel', ->
  beforeEach ->
    @s = new Curve.SelectionModel()
    @path = {id: 1}

    @s.on 'change:selected', @onSelected = jasmine.createSpy()

  it 'fires events when changing selection', ->
    @s.setSelected(@path)

    expect(@onSelected).toHaveBeenCalled()
    expect(@onSelected.mostRecentCall.args[0]).toEqual object: @path

describe 'Curve.SelectionView', ->
  beforeEach ->
    loadFixtures 'canvas.html'
    window.raphael = Raphael("canvas")

  beforeEach ->
    @model = new Curve.SelectionModel()
    @s = new Curve.SelectionView(@model)
    @path = new Curve.Path()
    @path.addPathPoint(new Curve.PathPoint([50, 50], [-10, 0], [10, 0]))
    @path.close()

  it 'creates nodes when selecting a path', ->
    @model.setSelected(@path)

    expect($('svg circle').length).toEqual 1
    expect($('svg path').length).toEqual 2
