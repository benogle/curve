utils = window.Curve

#
class Node extends EventEmitter
  constructor: (point, handleIn, handleOut, @isJoined=false) ->
    @setPoint(point)
    @setHandleIn(handleIn) if handleIn
    @setHandleOut(handleOut) if handleOut

    @isMoveNode = false
    @isCloseNode = false

  getAbsoluteHandleIn: ->
    if @handleIn
      @point.add(@handleIn)
    else
      @point
  getAbsoluteHandleOut: ->
    if @handleOut
      @point.add(@handleOut)
    else
      @point

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

  computeIsjoined: ->
    @isJoined = (not @handleIn and not @handleOut) or (@handleIn and @handleOut and @handleIn.x == -@handleOut.x and @handleIn.y == -@handleOut.y)

  set: (attribute, value) ->
    old = @[attribute]
    @[attribute] = value

    event = "change:#{attribute}"
    eventArgs = {event, value, old}

    @emit event, this, eventArgs
    @emit 'change', this, eventArgs

_.extend(window.Curve, {Node})
