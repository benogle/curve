{Emitter} = require 'event-kit'
Point = require './point'

module.exports =
class Node
  constructor: (point, handleIn, handleOut, @isJoined=false) ->
    @emitter = new Emitter

    @setPoint(point)
    @setHandleIn(handleIn) if handleIn
    @setHandleOut(handleOut) if handleOut

  on: (args...) -> @emitter.on(args...)

  join: (referenceHandle='handleIn') ->
    @isJoined = true
    @["set#{referenceHandle.replace('h', 'H')}"](@[referenceHandle])

  setPath: (@path) ->

  getPath: -> @path

  getPoint: ->
    @_transformPoint(@point)
  getHandleIn: -> @handleIn
  getHandleOut: -> @handleOut

  getAbsoluteHandleIn: ->
    if @handleIn
      @_transformPoint(@point.add(@handleIn))
    else
      @getPoint()

  getAbsoluteHandleOut: ->
    if @handleOut
      @_transformPoint(@point.add(@handleOut))
    else
      @getPoint()

  setAbsoluteHandleIn: (point) ->
    @setHandleIn(Point.create(point).subtract(@point))

  setAbsoluteHandleOut: (point) ->
    @setHandleOut(Point.create(point).subtract(@point))

  setPoint: (point) ->
    @set('point', Point.create(point))
  setHandleIn: (point) ->
    point = Point.create(point) if point
    @set('handleIn', point)
    @set('handleOut', if point then new Point(0,0).subtract(point) else point) if @isJoined
  setHandleOut: (point) ->
    point = Point.create(point) if point
    @set('handleOut', point)
    @set('handleIn', if point then new Point(0,0).subtract(point) else point) if @isJoined

  computeIsjoined: ->
    @isJoined = (not @handleIn and not @handleOut) or (@handleIn and @handleOut and Math.round(@handleIn.x) == Math.round(-@handleOut.x) and Math.round(@handleIn.y) == Math.round(-@handleOut.y))

  set: (attribute, value) ->
    old = @[attribute]
    @[attribute] = value

    event = "change:#{attribute}"
    eventArgs = {event, value, old}

    @emitter.emit event, this, eventArgs
    @emitter.emit 'change', this, eventArgs

  translate: (point) ->
    point = Point.create(point)
    @set('point', @point.add(point))

  _transformPoint: (point) ->
    transform = @path?.getTransform()
    point = transform.transformPoint(point) if transform?
    point
