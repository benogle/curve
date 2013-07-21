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

  constructor: (@model) ->
    @path = null
    @nodes = null
    @handles = null
    @model.on 'change:selected', @onChangeSelected
    @model.on 'change:selectedNode', @onChangeSelectedNode

  renderSelectedObject: ->
    return unless object = @model.selected

    @model.selected.render(@path)

    @nodes = raphael.set() unless @nodes

    nodeDifference = object.nodes.length - @nodes.length
    if nodeDifference > 0
      for i in [0...nodeDifference]
        circle = raphael.circle(0, 0, @nodeSize)
        circle.node.setAttribute('class','selected-node')
        @nodes.push(circle)
    else if nodeDifference < 0
      for i in [object.nodes.length...@nodes.length]
        @nodes[i].remove()
        @nodes.exclude(@nodes[i])

    for i in [0...object.nodes.length]
      node = object.nodes[i]
      @nodes[i].attr(cx: node.point.x, cy: node.point.y)

  renderSelectedNode: ->
    return unless node = @model.selectedNode

  onChangeSelected: ({object}) =>
    @setSelectedObject(object)
  onChangeSelectedNode: ({object}) =>
    @setSelectedNode(object)

  setSelectedObject: (object) ->
    if @nodes
      @nodes.remove()
      @nodes = null

    @path.remove() if @path
    @path = null
    if object
      @path = object.path.clone().toFront()
      @path.node.setAttribute('class', 'selected-path')

    @renderSelectedObject()

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
