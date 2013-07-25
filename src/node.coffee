utils = window.Curve

#
class Node extends EventEmitter
  constructor: (point, handleIn, handleOut) ->
    @setPoint(point)
    @setHandleIn(handleIn)
    @setHandleOut(handleOut)
    @isJoined = true

  getAbsoluteHandleIn: ->
    @point.add(@handleIn)
  getAbsoluteHandleOut: ->
    @point.add(@handleOut)

  setAbsoluteHandleIn: (point) ->
    @setHandleIn(Point.create(point).subtract(@point))
  setAbsoluteHandleOut: (point) ->
    @setHandleOut(Point.create(point).subtract(@point))

  setPoint: (point) ->
    @set('point', Point.create(point))
  setHandleIn: (point) ->
    point = Point.create(point)
    @set('handleIn', point)
    @set('handleOut', new Point(0,0).subtract(point)) if @isJoined
  setHandleOut: (point) ->
    point = Point.create(point)
    @set('handleOut', point)
    @set('handleIn', new Point(0,0).subtract(point)) if @isJoined

  set: (attribute, value) ->
    old = @[attribute]
    @[attribute] = value

    event = "change:#{attribute}"
    eventArgs = {event, value, old}

    @emit event, this, eventArgs
    @emit 'change', this, eventArgs

_.extend(window.Curve, {Node})
