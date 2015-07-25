{EventEmitter} = require 'events'

# The display for a selected object. i.e. the red or blue outline around the
# selected object.
#
# It basically cops the underlying object's attributes (path definition, etc.)
module.exports =
class ObjectSelection extends EventEmitter
  constructor: (@svgDocument, @options={}) ->
    @options.class ?= 'object-selection'

  setObject: (object) ->
    @_unbindObject(@object)
    old = object
    @object = object
    @_bindObject(@object)

    @trackingObject.remove() if @trackingObject
    @trackingObject = null
    if @object
      @trackingObject = @object.cloneElement(@svgDocument).back()
      @trackingObject.node.setAttribute('class', @options.class + ' invisible-to-hit-test')
      @render()
    @emit 'change:object', {objectSelection: this, @object, old}

  render: =>
    @object.render(@trackingObject)

  _bindObject: (object) ->
    return unless object
    object.on 'change', @render

  _unbindObject: (object) ->
    return unless object
    object.removeListener 'change', @render
