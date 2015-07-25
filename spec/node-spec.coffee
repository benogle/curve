Point = require '../src/point'
Node = require '../src/node'

describe 'Node', ->
  [node] = []

  beforeEach ->
    node = new Node([50, 50], [-10, 0], [10, 0], true)

  describe 'joined handles', ->
    it 'updating one handle updates the other', ->
      node.setHandleIn([20, 30])
      expect(node.handleOut).toEqual new Point(-20, -30)

      node.setHandleOut([15, -5])
      expect(node.handleIn).toEqual new Point(-15, 5)

    it 'join() will set the other non-joined handle', ->
      node.isJoined = false
      node.setHandleIn([0, 0])

      node.join('handleOut')
      expect(node.handleIn).toEqual new Point(-10, 0)

    it 'setting handle to null, mirrors', ->
      node.setHandleIn(null)
      expect(node.handleOut).toEqual null

  describe "::translate()", ->
    it "translates the node and the handles", ->
      node.translate(new Point(-25, 10))
      expect(node.getPoint()).toEqual new Point(25, 60)
      expect(node.getHandleIn()).toEqual new Point(-10, 0)
      expect(node.getHandleOut()).toEqual new Point(10, 0)
