{CompositeDisposable} = require 'event-kit'

# A rectangle display for a selected object. i.e. the red or blue outline around
# the selected object. This one just displays wraps the object in a rectangle.
module.exports =
class RectangleSelection
  constructor: (@svgDocument, @options={}) ->
    @options.class ?= 'object-selection'

  setObject: (object) ->
    return if object is @object
    @_unbindObject()
    @object = object
    @_bindObject(@object)

    @trackingObject.remove() if @trackingObject
    @trackingObject = null
    if @object
      @trackingObject = @svgDocument.getToolLayer().rect()
      @trackingObject.node.setAttribute('class', @options.class + ' invisible-to-hit-test')
      @trackingObject.back()
      @render()
    return

  render: =>
    position = @object.get('position')
    size = @object.get('size')
    @trackingObject.attr
      x: Math.round(position.x) - .5
      y: Math.round(position.y) - .5
      width: Math.round(size.width) + 1
      height: Math.round(size.height) + 1
      transform: @object.get('transform')

  _bindObject: (object) ->
    return unless object
    @selectedObjectSubscriptions = new CompositeDisposable
    @selectedObjectSubscriptions.add object.on('change', @render)

  _unbindObject: ->
    @selectedObjectSubscriptions?.dispose()
    @selectedObjectSubscriptions = null
