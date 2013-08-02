_ = window._ or require 'underscore'

EventEmitter = window.EventEmitter or require('events').EventEmitter

#
class Subpath extends EventEmitter
  constructor: ({isClosed}={}) ->
    @nodes = []
    @isClosed = !!isClosed

  toString: ->
    "Subpath #{@toPathString()}"

  addNode: (node) ->
    @insertNode(node, @nodes.length)

  insertNode: (node, index) ->
    @_bindNode(node)
    @nodes.splice(index, 0, node)

    args =
      event: 'insert:node'
      index: index
      value: node
    @emit('insert:node', this, args)
    @emit('change', this, args)

  close: ->
    @isClosed = true

    args = event: 'close'
    @emit('close', this, args)
    @emit('change', this, args)

  toPathString: ->
    path = ''
    lastPoint = null

    makeCurve = (fromNode, toNode) ->
      curve = []
      curve = curve.concat(fromNode.getAbsoluteHandleOut().toArray())
      curve = curve.concat(toNode.getAbsoluteHandleIn().toArray())
      curve = curve.concat(toNode.point.toArray())
      'C' + curve.join(',')

    closePath = (firstNode, lastNode)->
      closingPath = ''
      closingPath += makeCurve(lastNode, firstNode) if lastNode.handleOut or firstNode.handleIn
      closingPath += 'Z'

    for node in @nodes
      if path
        path += makeCurve(lastNode, node)
      else
        path += 'M' + node.point.toArray().join(',')

      lastNode = node

    path += closePath(@nodes[0], @nodes[@nodes.length-1]) if @isClosed
    path

  onNodeChange: (node, eventArgs) =>
    index = @_findNodeIndex(node)
    @emit 'change', this, _.extend({index}, eventArgs)

  _bindNode: (node) ->
    node.on 'change', @onNodeChange

  _findNodeIndex: (node) ->
    for i in [0...@nodes.length]
      return i if @nodes[i] == node
    -1

Curve.Subpath = Subpath
