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

  it 'handles null handles', ->
    path = new Curve.Path()
    path.addNode(new Curve.Node([60, 80]))
    path.addNode(new Curve.Node([70, 90]))
    path.render()

    el = $('svg path')
    expect(el.attr('d')).toEqual('M60,80C60,80,70,90,70,90')

  describe 'creating from path string', ->
    it 'can be created', ->
      pathString = 'M50,50C60,50,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
      node = svg.path(pathString)
      @path = new Curve.Path(node)

      expect(@path.toPathString()).toEqual pathString

    it 'can be created with non-wrapped closed shapes', ->
      pathString = 'M10,10C20,10,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
      node = svg.path(pathString)
      @path = new Curve.Path(node)

      expect(@path.toPathString()).toEqual pathString

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
