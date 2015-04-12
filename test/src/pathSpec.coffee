describe 'Curve.Path', ->
  [svg, path] = []

  beforeEach ->
    loadFixtures 'canvas.html'
    svg = SVG("canvas")

  it 'has empty path string after creation', ->
    path = new Curve.Path(svg)
    expect(path.getPathString()).toEqual ''

  it 'has empty path string with empty subpath', ->
    path = new Curve.Path(svg)
    path.model._addSubpath(new Curve.Subpath({path}))
    expect(path.getPathString()).toEqual ''

  it 'can be created', ->
    path = new Curve.Path(svg)
    path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
    path.addNode(new Curve.Node([80, 60], [-10, -5], [10, 5]))
    path.addNode(new Curve.Node([60, 80], [10, 0], [-10, 0]))
    path.close()

    el = path.svgEl
    expect(el.attr('d')).toMatch(/^M50,50C60,50/)
    expect(el.attr('d')).toMatch(/Z$/)

  it 'is associated with the node', ->
    path = new Curve.Path(svg)
    path.addNode(new Curve.Node([60, 80], [10, 0], [-10, 0]))
    path.render()

    el = path.svgEl
    expect(Curve.Utils.getObjectFromNode(el.node)).toEqual path

  it 'handles null handles', ->
    path = new Curve.Path(svg)
    path.addNode(new Curve.Node([60, 80]))
    path.addNode(new Curve.Node([70, 90]))
    path.render()

    el = path.svgEl
    expect(el.attr('d')).toEqual('M60,80L70,90')

  describe 'creating from path string', ->
    it 'can be created', ->
      pathString = 'M50,50C60,50,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
      node = svg.path(pathString)
      path = new Curve.Path(svg, svgEl: node)

      expect(path.getPathString()).toEqual pathString

    it 'can be created with non-wrapped closed shapes', ->
      pathString = 'M10,10C20,10,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
      node = svg.path(pathString)
      path = new Curve.Path(svg, svgEl: node)

      expect(path.getPathString()).toEqual pathString

    it 'handles move nodes', ->
      pathString = 'M50,50C60,50,70,55,80,60C90,65,68,103,60,80Z M10,10C60,50,70,55,50,70C90,65,68,103,60,80Z'
      node = svg.path(pathString)
      path = new Curve.Path(svg, svgEl: node)

      expect(path.getPathString()).toEqual pathString

  describe "::translate()", ->
    beforeEach ->
      path = new Curve.Path(svg)
      path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
      path.addNode(new Curve.Node([80, 60], [-10, -5], [10, 5]))
      path.addNode(new Curve.Node([60, 80], [10, 0], [-10, 0]))
      path.close()

    it "translates all the nodes", ->
      path.model.translate(new Curve.Point(-10, 10))
      expect(path.getNodes()[0].getPoint()).toEqual new Curve.Point(40, 60)
      expect(path.getNodes()[1].getPoint()).toEqual new Curve.Point(70, 70)
      expect(path.getNodes()[2].getPoint()).toEqual new Curve.Point(50, 90)

  describe 'updating via the the node attributes', ->
    beforeEach ->
      path = new Curve.Path(svg)
      path.addNode(new Curve.Node([60, 60], [-10, 0], [10, 0]))
      expect(path.getPathString()).toBe 'M60,60'

    it 'updates the model when the path string changes', ->
      newPathString = 'M50,50C60,50,70,55,80,60C90,65,70,80,60,80C50,80,40,50,50,50Z'
      el = path.svgEl
      el.attr('d', newPathString)
      path.updateFromAttributes()

      nodes = path.getNodes()
      expect(nodes.length).toBe 3
      expect(nodes[0].getPoint()).toEqual new Curve.Point(50, 50)
      expect(nodes[1].getPoint()).toEqual new Curve.Point(80, 60)
      expect(nodes[2].getPoint()).toEqual new Curve.Point(60, 80)
      expect(el.attr('d')).toBe newPathString

    it 'updates the model when the transform changes', ->
      el = path.svgEl
      el.attr(transform: 'translate(10 20)')
      path.updateFromAttributes()

      transformString = path.model.getTransformString()
      expect(transformString).toBe 'translate(10 20)'

    it "updates the node points when the transform changes", ->
      el = path.svgEl
      el.attr(transform: 'translate(10 20)')
      path.updateFromAttributes()

      nodes = path.getNodes()
      expect(nodes[0].getPoint()).toEqual new Curve.Point(70, 80)
      expect(nodes[0].getAbsoluteHandleIn()).toEqual new Curve.Point(60, 80)
      expect(nodes[0].getAbsoluteHandleOut()).toEqual new Curve.Point(80, 80)


  describe 'updating via the model', ->
    beforeEach ->
      path = new Curve.Path(svg)
      path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
      path.addNode(new Curve.Node([80, 60], [-10, -5], [10, 5]))
      path.addNode(new Curve.Node([60, 80], [10, 0], [-10, 0]))
      path.close()

    it 'renders when node point is updated', ->
      path.getSubpaths()[0].nodes[0].setPoint([70, 70])
      el = path.svgEl
      expect(el.attr('d')).toMatch(/^M70,70C80,70/)

    it 'kicks out event when changes', ->
      spy = jasmine.createSpy()
      path.on 'change', spy
      path.getSubpaths()[0].nodes[0].setPoint([70, 70])
      expect(spy).toHaveBeenCalled()

    it 'kicks out event when closed', ->
      closespy = jasmine.createSpy()
      changespy = jasmine.createSpy()
      path.on 'change', closespy
      path.close()
      expect(closespy).toHaveBeenCalled()

    it 'node added adds node to the end', ->
      node = new Curve.Node([40, 60], [0, 0], [0, 0])
      path.on 'change', spy = jasmine.createSpy()
      path.on 'insert:node', insertSpy = jasmine.createSpy()
      path.addNode(node)
      expect(path.getSubpaths()[0].nodes[3]).toEqual node
      expect(spy).toHaveBeenCalled()
      expect(insertSpy).toHaveBeenCalled()
      expect(insertSpy.mostRecentCall.args[1].index).toEqual 3
      expect(insertSpy.mostRecentCall.args[1].node).toEqual node
      expect(insertSpy.mostRecentCall.args[1].path).toEqual path

    it 'node inserted inserts node in right place', ->
      node = new Curve.Node([40, 60], [0, 0], [0, 0])
      spy = jasmine.createSpy()
      path.on 'change', spy
      path.insertNode(node, 0)
      expect(path.getSubpaths()[0].nodes[0]).toEqual node
      expect(spy).toHaveBeenCalled()
