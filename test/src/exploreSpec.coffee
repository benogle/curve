describe 'Curve.Path', ->
  beforeEach ->
    loadFixtures 'canvas.html'
    @raphael = Raphael("canvas")

  it 'can be created', ->
    path = new Curve.Path(@raphael)
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
