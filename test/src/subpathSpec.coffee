describe 'Curve.Subpath', ->
  beforeEach ->

  describe 'toPathString', ->
    it 'outputs empty path string with NO nodes', ->
      subpath = new Curve.Subpath()
      expect(subpath.toPathString()).toEqual ''

    it 'outputs empty path string closed with NO nodes', ->
      subpath = new Curve.Subpath()
      subpath.close()
      expect(subpath.toPathString()).toEqual ''

    it 'outputs correct path string with nodes', ->
      subpath = new Curve.Subpath()
      subpath.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
      subpath.addNode(new Curve.Node([80, 60], [-10, -5], [10, 5]))
      subpath.addNode(new Curve.Node([60, 80], [10, 0], [-10, 0]))
      subpath.close()

      pathStr = subpath.toPathString()
      expect(pathStr).toMatch(/^M50,50C60,50/)
      expect(pathStr).toMatch(/Z$/)

  describe 'creating', ->
    it 'can be created with nodes and close', ->
      nodes = [
        new Curve.Node([50, 50], [-10, 0], [10, 0])
        new Curve.Node([80, 60], [-10, -5], [10, 5])
        new Curve.Node([60, 80], [10, 0], [-10, 0])
      ]
      @path = new Curve.Subpath({closed: true, nodes})

      expect(@path.closed).toEqual true
      expect(@path.nodes.length).toEqual 3

  describe 'updating', ->
    beforeEach ->
      @path = new Curve.Subpath()
      @path.addNode(new Curve.Node([50, 50], [-10, 0], [10, 0]))
      @path.addNode(new Curve.Node([80, 60], [-10, -5], [10, 5]))
      @path.addNode(new Curve.Node([60, 80], [10, 0], [-10, 0]))
      @path.close()

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

    it 'nodes can be replaced', ->
      @path.on 'change', changeSpy = jasmine.createSpy()
      @path.on 'replace:nodes', replaceSpy = jasmine.createSpy()

      nodes = [
        new Curve.Node([20, 30], [-10, 0], [10, 0])
      ]
      @path.setNodes(nodes)

      expect(changeSpy).toHaveBeenCalled()
      expect(replaceSpy).toHaveBeenCalled()
      expect(replaceSpy.mostRecentCall.args[1]).toEqual
        event: 'replace:nodes'
        value: nodes

      expect(changeSpy.callCount).toEqual 1
      nodes[0].setPoint([70, 70])
      expect(changeSpy.callCount).toEqual 2
