Node = require '../src/node'
Point = require '../src/point'
Subpath = require '../src/subpath'
PathParser = require '../src/path-parser'

describe 'Subpath', ->
  path = null
  describe 'toPathString', ->
    it 'outputs empty path string with NO nodes', ->
      subpath = new Subpath()
      expect(subpath.toPathString()).toEqual ''

    it 'outputs empty path string closed with NO nodes', ->
      subpath = new Subpath()
      subpath.close()
      expect(subpath.toPathString()).toEqual ''

    it 'outputs correct path string with nodes', ->
      subpath = new Subpath()
      subpath.addNode(new Node([50, 50], [-10, 0], [10, 0]))
      subpath.addNode(new Node([80, 60], [-10, -5], [10, 5]))
      subpath.addNode(new Node([60, 80], [10, 0], [-10, 0]))
      subpath.close()

      pathStr = subpath.toPathString()
      expect(pathStr).toMatch(/^M50,50C60,50/)
      expect(pathStr).toMatch(/Z$/)

    describe 'from parsed path', ->
      it 'uses shorthand commands rather than all beziers', ->
        path = 'M512,384L320,576h128v320h128V576H704L512,384z'
        parsedPath = PathParser.parsePath(path)
        path = new Subpath(parsedPath.subpaths[0])

        pathString = path.toPathString()
        expect(pathString).toEqual 'M512,384L320,576H448V896H576V576H704Z'

  describe 'creating', ->
    it 'can be created with nodes and close', ->
      nodes = [
        new Node([50, 50], [-10, 0], [10, 0])
        new Node([80, 60], [-10, -5], [10, 5])
        new Node([60, 80], [10, 0], [-10, 0])
      ]
      path = new Subpath({closed: true, nodes})

      expect(path.closed).toEqual true
      expect(path.nodes.length).toEqual 3

  describe "::translate()", ->
    beforeEach ->
      path = new Subpath()
      path.addNode(new Node([50, 50], [-10, 0], [10, 0]))
      path.addNode(new Node([80, 60], [-10, -5], [10, 5]))
      path.addNode(new Node([60, 80], [10, 0], [-10, 0]))
      path.close()

    it "translates all the nodes", ->
      path.translate(new Point(-10, 10))
      expect(path.getNodes()[0].getPoint()).toEqual new Point(40, 60)
      expect(path.getNodes()[1].getPoint()).toEqual new Point(70, 70)
      expect(path.getNodes()[2].getPoint()).toEqual new Point(50, 90)

  describe 'updating', ->
    beforeEach ->
      path = new Subpath()
      path.addNode(new Node([50, 50], [-10, 0], [10, 0]))
      path.addNode(new Node([80, 60], [-10, -5], [10, 5]))
      path.addNode(new Node([60, 80], [10, 0], [-10, 0]))
      path.close()

    it 'kicks out event when changes', ->
      spy = jasmine.createSpy()
      path.on 'change', spy
      path.nodes[0].setPoint([70, 70])
      expect(spy).toHaveBeenCalled()

    it 'kicks out event when closed', ->
      closespy = jasmine.createSpy()
      changespy = jasmine.createSpy()
      path.on 'change', changespy
      path.close()
      expect(changespy).toHaveBeenCalled()

    it 'adds a node to the end with addNode and emits an event', ->
      node = new Node([40, 60], [0, 0], [0, 0])

      spy = jasmine.createSpy()
      path.on 'insert:node', spy

      path.addNode(node)

      expect(path.nodes[3]).toEqual node
      expect(spy.calls.mostRecent().args[0]).toEqual
        subpath: path
        index: 3
        node: node

    it 'removes a node with removeNode and emits an event', ->
      node = path.nodes[1]
      path.on 'remove:node', removedSpy = jasmine.createSpy()
      path.on 'change', changedSpy = jasmine.createSpy()
      path.removeNode(node)

      expect(changedSpy).toHaveBeenCalled()
      expect(removedSpy.calls.mostRecent().args[0]).toEqual
        subpath: path
        index: 1
        node: node

      expect(path.nodes.indexOf(node)).toBe -1
      expect(path.nodes).toHaveLength 2

    it 'node inserted inserts node in right place', ->
      node = new Node([40, 60], [0, 0], [0, 0])

      spy = jasmine.createSpy()
      path.on 'insert:node', spy

      path.insertNode(node, 0)

      expect(path.nodes[0]).toEqual node
      expect(spy.calls.mostRecent().args[0]).toEqual
        subpath: path
        index: 0
        node: node

    it 'nodes can be replaced', ->
      path.on 'change', changeSpy = jasmine.createSpy()

      nodes = [new Node([20, 30], [-10, 0], [10, 0])]
      path.setNodes(nodes)

      expect(changeSpy).toHaveBeenCalled()
      expect(changeSpy.calls.count()).toEqual 1
      nodes[0].setPoint([70, 70])
      expect(changeSpy.calls.count()).toEqual 2
