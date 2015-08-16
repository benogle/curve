{CompositeDisposable} = require 'event-kit'
Delegator = require 'delegato'

Transform = require './transform'
Point = require './point'
Size = require './size'
Model = require './model'

IDS = 0

module.exports =
class RectangleModel extends Model
  constructor: ->
    super(['transform', 'position', 'size', 'fill'])
    @id = IDS++
    @transform = new Transform

    @addFilter 'size', (value) => Size.create(value)
    @addFilter 'position', (value) => Point.create(value)
    @addFilter 'transform', (value) =>
      if value is 'matrix(1,0,0,1,0,0)' then null else value

    @subscriptions = new CompositeDisposable
    @subscriptions.add @on 'change:transform', ({value}) => @transform.setTransformString(value)

  destroy: ->
    @subscriptions.dispose()

  ###
  Section: Public Methods
  ###

  getType: -> 'Rectangle'

  getID: -> "#{@getType()}-#{@id}"

  toString: -> "{Rect #{@id}: #{@get('position')} #{@get('size')}"

  ###
  Section: Position / Size Methods
  ###

  getTransform: -> @transform

  translate: (point) ->
    point = Point.create(point)
    @set(position: @get('position').add(point))
