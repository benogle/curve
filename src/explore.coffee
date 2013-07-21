attrs = {fill: '#ccc'}
utils = window.Curve

#
class Path
  constructor: () ->
    @path = null
    @pathPoints = []
    @isClosed = false
    @path = @_createRaphaelObject([])

  addPathPoint: (pathPoint) ->
    @pathPoints.push(pathPoint)
    @render()

  close: ->
    @isClosed = true
    @render()

  render: (path=@path)->
    path.attr(path: @toPathArray())

  toPathArray: ->
    path = []
    lastPoint = null

    makeCurve = (lastPoint, point) ->
      curve = ['C']
      curve = curve.concat(lastPoint.getAbsoluteHandleOut().toArray())
      curve = curve.concat(point.getAbsoluteHandleIn().toArray())
      curve = curve.concat(point.point.toArray())
      curve

    for point in @pathPoints

      if path.length == 0
        path.push(['M'].concat(point.point.toArray()))
      else
        path.push(makeCurve(lastPoint, point))

      lastPoint = point

    if @isClosed
      path.push(makeCurve(@pathPoints[@pathPoints.length-1], @pathPoints[0]))
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
class PathPoint extends EventEmitter
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

  clearSelected: ->
    @setSelected(null)

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

  #render: ->

  onChangeSelected: ({object}) =>
    @setSelectionObject(object)

  setSelectionObject: (object) ->
    @path = object.path.clone().toFront().attr(@selectionAttrs)

    @nodes.remove() if @nodes
    @nodes = raphael.set()

    for pp in object.pathPoints
      @nodes.push(raphael.circle(pp.point.x, pp.point.y, @nodeSize))

    @nodes.attr(@nodeAttrs)

_.extend(window.Curve, {Path, Curve, Point, PathPoint, SelectionModel, SelectionView})

window.main = ->
  @raphael = r = Raphael("canvas")
  @path = new Path(r)
  @path.addPathPoint(new PathPoint([50, 50], [-10, 0], [10, 0]))
  @path.addPathPoint(new PathPoint([80, 60], [-10, -5], [10, 5]))
  @path.addPathPoint(new PathPoint([60, 80], [10, 0], [-10, 0]))
  @path.close()

  @selectionModel = new SelectionModel()
  @selectionView = new SelectionView(selectionModel)

  @selectionModel.setSelected(@path)
