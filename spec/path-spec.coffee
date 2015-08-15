SVGDocument = require '../src/svg-document'

Node = require '../src/node'
Path = require '../src/path'
Point = require '../src/point'
Subpath = require '../src/subpath'
Utils = require '../src/utils'

describe 'Path', ->
  [svg, path] = []

  beforeEach ->
    canvas = document.createElement('canvas')
    jasmine.attachToDOM(canvas)
    svg = new SVGDocument(canvas)

  describe "creation", ->
    it 'has an id', ->
      path = new Path(svg)
      expect(path.getID()).toBe "Path-#{path.getModel().id}"

    it 'has empty path string after creation', ->
      path = new Path(svg)
      expect(path.get('path')).toEqual ''

    it 'registers itself with the document', ->
      path = new Path(svg)
      expect(svg.getObjects()).toContain path

  it 'emits an event when it is removed', ->
    path = new Path(svg)
    path.on 'remove', removeSpy = jasmine.createSpy()
    path.remove()
    expect(removeSpy).toHaveBeenCalledWith({object: path})

  it 'has empty path string with empty subpath', ->
    path = new Path(svg)
    path.model._addSubpath(new Subpath({path}))
    expect(path.get('path')).toEqual ''

  it 'can be created', ->
    path = new Path(svg)
    path.addNode(new Node([50, 50], [-10, 0], [10, 0]))
    path.addNode(new Node([80, 60], [-10, -5], [10, 5]))
    path.addNode(new Node([60, 80], [10, 0], [-10, 0]))
    path.close()

    el = path.svgEl
    expect(el.attr('d')).toMatch(/^M50,50C60,50/)
    expect(el.attr('d')).toMatch(/Z$/)

  it 'is associated with the node', ->
    path = new Path(svg)
    path.addNode(new Node([60, 80], [10, 0], [-10, 0]))
    path.render()

    el = path.svgEl
    expect(Utils.getObjectFromNode(el.node)).toEqual path

  it 'handles null handles', ->
    path = new Path(svg)
    path.addNode(new Node([60, 80]))
    path.addNode(new Node([70, 90]))
    path.render()

    el = path.svgEl
    expect(el.attr('d')).toEqual('M60,80L70,90')

  describe 'creating from path string', ->
    it 'can be created', ->
      pathString = 'M50,50C60,50,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
      node = svg.getSVGRoot().path(pathString)
      path = new Path(svg, svgEl: node)

      expect(path.get('path')).toEqual pathString

    it 'can be created with non-wrapped closed shapes', ->
      pathString = 'M10,10C20,10,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
      node = svg.getSVGRoot().path(pathString)
      path = new Path(svg, svgEl: node)

      expect(path.get('path')).toEqual pathString

    it 'handles move nodes', ->
      pathString = 'M50,50C60,50,70,55,80,60C90,65,68,103,60,80Z M10,10C60,50,70,55,50,70C90,65,68,103,60,80Z'
      node = svg.getSVGRoot().path(pathString)
      path = new Path(svg, svgEl: node)

      expect(path.get('path')).toEqual pathString

  describe "::translate()", ->
    beforeEach ->
      path = new Path(svg)
      path.addNode(new Node([50, 50], [-10, 0], [10, 0]))
      path.addNode(new Node([80, 60], [-10, -5], [10, 5]))
      path.addNode(new Node([60, 80], [10, 0], [-10, 0]))
      path.close()

    it "translates all the nodes", ->
      path.model.translate(new Point(-10, 10))
      expect(path.getNodes()[0].getPoint()).toEqual new Point(40, 60)
      expect(path.getNodes()[1].getPoint()).toEqual new Point(70, 70)
      expect(path.getNodes()[2].getPoint()).toEqual new Point(50, 90)

  describe 'updating via the the node attributes', ->
    beforeEach ->
      path = new Path(svg)
      path.addNode(new Node([60, 60], [-10, 0], [10, 0]))
      expect(path.get('path')).toBe 'M60,60'

    it 'updates the model when the path string changes', ->
      newPathString = 'M50,50C60,50,70,55,80,60C90,65,70,80,60,80C50,80,40,50,50,50Z'
      el = path.svgEl
      el.attr('d', newPathString)
      path.updateFromAttributes()

      nodes = path.getNodes()
      expect(nodes.length).toBe 3
      expect(nodes[0].getPoint()).toEqual new Point(50, 50)
      expect(nodes[1].getPoint()).toEqual new Point(80, 60)
      expect(nodes[2].getPoint()).toEqual new Point(60, 80)
      expect(el.attr('d')).toBe newPathString

    it 'updates the model when the transform changes', ->
      el = path.svgEl
      el.attr(transform: 'translate(10 20)')
      path.updateFromAttributes()

      transformString = path.model.get('transform')
      expect(transformString).toBe 'translate(10 20)'

    it "updates the node points when the transform changes", ->
      el = path.svgEl
      el.attr(transform: 'translate(10 20)')
      path.updateFromAttributes()

      nodes = path.getNodes()
      expect(nodes[0].getPoint()).toEqual new Point(70, 80)
      expect(nodes[0].getAbsoluteHandleIn()).toEqual new Point(60, 80)
      expect(nodes[0].getAbsoluteHandleOut()).toEqual new Point(80, 80)


  describe 'updating via the model', ->
    beforeEach ->
      path = new Path(svg)
      path.addNode(new Node([50, 50], [-10, 0], [10, 0]))
      path.addNode(new Node([80, 60], [-10, -5], [10, 5]))
      path.addNode(new Node([60, 80], [10, 0], [-10, 0]))

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
      path.on 'change', closespy
      path.close()
      expect(closespy).toHaveBeenCalled()

    it 'node added adds node to the end', ->
      node = new Node([40, 60], [0, 0], [0, 0])
      path.on 'change', spy = jasmine.createSpy()
      path.on 'insert:node', insertSpy = jasmine.createSpy()
      path.addNode(node)
      expect(path.getSubpaths()[0].nodes[3]).toEqual node
      expect(spy).toHaveBeenCalled()
      expect(insertSpy).toHaveBeenCalled()
      expect(insertSpy.calls.mostRecent().args[0].index).toEqual 3
      expect(insertSpy.calls.mostRecent().args[0].node).toEqual node
      expect(insertSpy.calls.mostRecent().args[0].object).toEqual path

    it 'node inserted inserts node in right place', ->
      node = new Node([40, 60], [0, 0], [0, 0])
      spy = jasmine.createSpy()
      path.on 'change', spy
      path.insertNode(node, 0)
      expect(path.getSubpaths()[0].nodes[0]).toEqual node
      expect(spy).toHaveBeenCalled()
