window.Curve = window.Curve or {}

utils =
  getObjectFromNode: (domNode) ->
    $.data(domNode, 'curve.object')
  setObjectOnNode: (domNode, object) ->
    $.data(domNode, 'curve.object', object)

_.extend(window.Curve, utils)

attrs = {fill: '#ccc'}
utils = window.Curve

###
  TODO
  * draw handles
  * move handles
  * move nodes
  * move entire object
  * select/deselect things
  * make new objects
###

#
class Path
  constructor: () ->
    @path = null
    @nodes = []
    @isClosed = false
    @path = @_createRaphaelObject([])

  addNode: (node) ->
    @nodes.push(node)
    @render()

  close: ->
    @isClosed = true
    @render()

  render: (path=@path)->
    path.attr(path: @toPathArray())

  toPathArray: ->
    path = []
    lastPoint = null

    makeCurve = (fromNode, toNode) ->
      curve = ['C']
      curve = curve.concat(fromNode.getAbsoluteHandleOut().toArray())
      curve = curve.concat(toNode.getAbsoluteHandleIn().toArray())
      curve = curve.concat(toNode.point.toArray())
      curve

    for node in @nodes

      if path.length == 0
        path.push(['M'].concat(node.point.toArray()))
      else
        path.push(makeCurve(lastNode, node))

      lastNode = node

    if @isClosed
      path.push(makeCurve(@nodes[@nodes.length-1], @nodes[0]))
      path.push(['Z'])

    path

  _createRaphaelObject: (pathArray) ->
    path = raphael.path(pathArray).attr(attrs)
    utils.setObjectOnNode(path.node, this)
    path


#
class Point extends EventEmitter
  @create: (x, y) ->
    return x if x instanceof Point
    new Point(x, y)

  constructor: (x, y) ->
    @set(x, y)

  set: (@x, @y) ->
    [@x, @y] = @x if _.isArray(@x)
    @emit 'change'

  add: (other) ->
    new Point(@x + other.x, @y + other.y)

  toArray: ->
    [@x, @y]

#
class Curve
  constructor: (@point1, @handle1, @point2, @handle2) ->

#
class Node extends EventEmitter
  constructor: (point, handleIn, handleOut) ->
    @point = Point.create(point)
    @handleIn = Point.create(handleIn)
    @handleOut = Point.create(handleOut)
    @isBroken = false
    @_curveIn = null
    @_curveOut = null

  getAbsoluteHandleIn: ->
    @point.add(@handleIn)
  getAbsoluteHandleOut: ->
    @point.add(@handleOut)

#
class SelectionModel extends EventEmitter
  constructor: ->
    @selected = null
    @selectedNode = null

  setSelected: (@selected) ->
    @emit 'change:selected', object: @selected

  setSelectedNode: (@selectedNode) ->
    @emit 'change:selectedNode', object: @selectedNode

  clearSelected: ->
    @setSelected(null)

  clearSelectedNode: ->
    @setSelectedNode(null)

#
class SelectionView
  nodeSize: 5
  selectionAttrs:
    fill: null
    stroke: '#09C'
    "stroke-width": 2,
    "stroke-linecap": "round"
  nodeAttrs:
    fill: '#fff'
    stroke: '#069'
    "stroke-width": 1,
    "stroke-linecap": "round"

  constructor: (@model) ->
    @path = null
    @nodes = null
    @handles = null
    @model.on 'change:selected', @onChangeSelected
    @model.on 'change:selectedNode', @onChangeSelectedNode

  #render: ->

  onChangeSelected: ({object}) =>
    @setSelectedObject(object)
  onChangeSelectedNode: ({object}) =>
    @setSelectedNode(object)

  setSelectedObject: (object) ->
    @nodes.remove() if @nodes

    return unless object

    @path = object.path.clone().toFront().attr(@selectionAttrs)
    @nodes = raphael.set()

    for node in object.nodes
      @nodes.push(raphael.circle(node.point.x, node.point.y, @nodeSize))

    @nodes.attr(@nodeAttrs)

  setSelectedNode: (node) ->


_.extend(window.Curve, {Path, Curve, Point, Node, SelectionModel, SelectionView})

window.main = ->
  @raphael = r = Raphael("canvas")
  @path = new Path(r)
  @path.addNode(new Node([50, 50], [-10, 0], [10, 0]))
  @path.addNode(new Node([80, 60], [-10, -5], [10, 5]))
  @path.addNode(new Node([60, 80], [10, 0], [-10, 0]))
  @path.close()

  @selectionModel = new SelectionModel()
  @selectionView = new SelectionView(selectionModel)

  @selectionModel.setSelected(@path)
