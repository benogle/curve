{CompositeDisposable} = require 'event-kit'

# The display for a selected object. i.e. the red or blue outline around the
# selected object.
#
# It basically cops the underlying object's attributes (path definition, etc.)
module.exports =
class ObjectSelection
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
      @trackingObject = @object.cloneElement(@svgDocument)
      @trackingObject.node.setAttribute('class', @options.class + ' invisible-to-hit-test')
      @svgDocument.getToolLayer().add(@trackingObject)
      @trackingObject.back()
      @render()
    return

  render: =>
    @object.render(@trackingObject)

  _bindObject: (object) ->
    return unless object
    @selectedObjectSubscriptions = new CompositeDisposable
    @selectedObjectSubscriptions.add object.on('change', @render)

  _unbindObject: ->
    @selectedObjectSubscriptions?.dispose()
    @selectedObjectSubscriptions = null
