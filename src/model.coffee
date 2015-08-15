{Emitter, CompositeDisposable} = require 'event-kit'
Delegator = require 'delegato'

module.exports =
class Model
  Delegator.includeInto(this)

  @delegatesMethods 'on', toProperty: 'emitter'

  constructor: (allowedProperties) ->
    @emitter = new Emitter
    @properties = {}
    for prop in allowedProperties
      @properties[prop] = null
    return

  set: (properties) ->
    return unless properties

    eventObject = null
    for property, value of properties
      continue unless @properties.hasOwnProperty(property)
      if propEventObject = @_setProperty(property, value)
        eventObject ?= {object: this, oldValue: {}, value: {}}
        eventObject.oldValue[property] = propEventObject.oldValue
        eventObject.value[property] = propEventObject.value
    @emitter.emit('change', eventObject) if eventObject?

  _setProperty: (property, value) ->
    return null if @properties[property] is value

    oldValue = @properties[property]
    @properties[property] = value

    eventObject = {object: this, oldValue, value, property}
    @emitter.emit("change:#{property}", eventObject)
    eventObject
