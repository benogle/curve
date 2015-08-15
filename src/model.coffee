{Emitter, CompositeDisposable} = require 'event-kit'
Delegator = require 'delegato'

module.exports =
class Model
  Delegator.includeInto(this)

  @delegatesMethods 'on', toProperty: 'emitter'

  constructor: (allowedProperties) ->
    @emitter = new Emitter
    @filters = {}
    @properties = {}
    for prop in allowedProperties
      @properties[prop] = null
    return

  get: (property) ->
    if property?
      @properties[property]
    else
      @properties

  set: (properties, options) ->
    return unless properties

    eventObject = null
    for property, value of properties
      continue unless @properties.hasOwnProperty(property)
      if propEventObject = @_setProperty(property, value, options)
        eventObject ?= {model: this, oldValue: {}, value: {}}
        eventObject.oldValue[property] = propEventObject.oldValue
        eventObject.value[property] = propEventObject.value
    @emitter.emit('change', eventObject) if eventObject?

  addFilter: (property, filter) ->
    @filters[property] = filter

  _setProperty: (property, value, options) ->
    return null if @properties[property] is value

    if @filters[property]? and (not options? or options.filter isnt false)
      value = @filters[property](value)
      return null if @properties[property] is value

    oldValue = @properties[property]
    @properties[property] = value

    eventObject = {model: this, oldValue, value, property}
    @emitter.emit("change:#{property}", eventObject)
    eventObject
