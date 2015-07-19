{EventEmitter} = require 'events'
Point = require './point.coffee'

# Subpath handles a single path from move node -> close node.
#
# Svg paths can have many subpaths like this:
#
#   M50,50L20,30Z  M4,5L2,3Z
#
# Each one of these will be represented by this Subpath class.
module.exports =
class Subpath extends EventEmitter
  constructor: ({@path, @closed, nodes}={}) ->
    @nodes = []
    @setNodes(nodes)
    @closed = !!@closed

  toString: ->
    "Subpath #{@toPathString()}"

  toPathString: ->
    path = ''
    lastPoint = null

    makeCurve = (fromNode, toNode) ->
      curve = ''
      if fromNode.handleOut or toNode.handleIn
        # use a bezier
        curve = []
        curve = curve.concat(fromNode.getAbsoluteHandleOut().toArray())
        curve = curve.concat(toNode.getAbsoluteHandleIn().toArray())
        curve = curve.concat(toNode.point.toArray())
        curve = "C#{curve.join(',')}"

      else if fromNode.point.x == toNode.point.x
        curve = "V#{toNode.point.y}"

      else if fromNode.point.y == toNode.point.y
        curve = "H#{toNode.point.x}"

      else
        curve = "L#{toNode.point.toArray().join(',')}"

      curve

    closePath = (firstNode, lastNode)->
      return '' unless firstNode and lastNode
      closingPath = ''
      closingPath += makeCurve(lastNode, firstNode) if lastNode.handleOut or firstNode.handleIn
      closingPath += 'Z'

    for node in @nodes
      if path
        path += makeCurve(lastNode, node)
      else
        path += 'M' + node.point.toArray().join(',')

      lastNode = node

    path += closePath(@nodes[0], @nodes[@nodes.length-1]) if @closed
    path

  getNodes: -> @nodes

  setNodes: (nodes) ->
    return unless nodes and Array.isArray(nodes)

    @_unbindNode(node) for node in @nodes
    @_bindNode(node) for node in nodes

    @nodes = nodes
    @emit('change', this)

  addNode: (node) ->
    @insertNode(node, @nodes.length)

  insertNode: (node, index) ->
    @_bindNode(node)
    @nodes.splice(index, 0, node)
    @emit('insert:node', this, {subpath: this, index, node})
    @emit('change', this)

  close: ->
    @closed = true
    @emit('change', this)

  translate: (point) ->
    point = Point.create(point)
    for node in @nodes
      node.translate(point)
    return

  onNodeChange: =>
    @emit 'change', this

  _bindNode: (node) ->
    node.setPath(@path)
    node.on 'change', @onNodeChange
  _unbindNode: (node) ->
    node.setPath(null)
    node.off 'change', @onNodeChange

  _findNodeIndex: (node) ->
    for i in [0...@nodes.length]
      return i if @nodes[i] == node
    -1
