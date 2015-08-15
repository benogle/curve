{Emitter} = require 'event-kit'
Delegator = require 'delegato'

Transform = require './transform'
Point = require './point'
Size = require './size'

IDS = 0

module.exports =
class RectangleModel
  position: null
  size: null
  transform: null

  constructor: ->
    @emitter = new Emitter
    @id = IDS++
    @transform = new Transform

  on: (args...) -> @emitter.on(args...)

  ###
  Section: Public Methods
  ###

  toString: -> "{Rect #{@id}: #{@position} #{@size}"

  ###
  Section: Position / Size Methods
  ###

  getPosition: -> @position

  setPosition: (x, y) ->
    @position = Point.create(x, y)
    @_emitChangeEvent()

  translate: (point) ->
    point = Point.create(point)
    @setPosition(@position.add(point))
    @_emitChangeEvent()

  getSize: -> @size

  setSize: (width, height) ->
    @size = Size.create(width, height)
    @_emitChangeEvent()

  ###
  Section: Editable Attributes
  ###

  getTransform: -> @transform

  getTransformString: -> @transform.toString()

  setTransformString: (transformString) ->
    if @transform.setTransformString(transformString)
      @_emitChangeEvent()

  ###
  Section: Private Methods
  ###

  _emitChangeEvent: ->
    @emitter.emit 'change', this
