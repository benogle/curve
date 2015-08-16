{Emitter, CompositeDisposable} = require 'event-kit'
Point = require './point'

# Subpath handles a single path from move node -> close node.
#
# Svg paths can have many subpaths like this:
#
#   M50,50L20,30Z  M4,5L2,3Z
#
# Each one of these will be represented by this Subpath class.
module.exports =
class Subpath
  constructor: ({@path, @closed, nodes}={}) ->
    @emitter = new Emitter
    @nodes = []
    @setNodes(nodes)
    @closed = !!@closed

  on: (args...) -> @emitter.on(args...)

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

    @_unbindNodes()
    @_bindNodes(nodes)

    @nodes = nodes
    @emitter.emit('change', this)

  addNode: (node) ->
    @insertNode(node, @nodes.length)

  insertNode: (node, index) ->
    @_bindNode(node)
    @nodes.splice(index, 0, node)
    @emitter.emit('insert:node', {subpath: this, index, node})
    @emitter.emit('change', this)

  isClosed: -> @closed

  close: ->
    @closed = true
    @emitter.emit('change', this)

  translate: (point) ->
    point = Point.create(point)
    for node in @nodes
      node.translate(point)
    return

  onNodeChange: =>
    @emitter.emit 'change', this

  _bindNode: (node) ->
    node.setPath(@path)
    @nodeChangeSubscriptions ?= new CompositeDisposable
    @nodeChangeSubscriptions.add node.on('change', @onNodeChange)

  _bindNodes: (nodes) ->
    for node in nodes
      @_bindNode(node)
    return

  _unbindNodes: ->
    for node in @nodes
      node.setPath(null)
    @nodeChangeSubscriptions?.dispose()
    @nodeChangeSubscriptions = null

  _findNodeIndex: (node) ->
    for i in [0...@nodes.length]
      return i if @nodes[i] == node
    -1
