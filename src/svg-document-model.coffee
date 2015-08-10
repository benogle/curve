{Emitter, CompositeDisposable} = require 'event-kit'

Size = require "./size"
Point = require "./point"

module.exports =
class SVGDocumentModel
  constructor: ->
    @emitter = new Emitter
    @reset()

  reset: ->
    @objects = []
    @objectSubscriptions?.dispose()
    @objectSubscriptions = new CompositeDisposable
    @objectSubscriptionsByObject = {}

  on: (args...) -> @emitter.on(args...)

  setObjects: (objects) ->
    @reset()
    options = {silent: true}
    for object in objects
      @registerObject(object, options)
    return

  getObjects: -> @objects

  registerObject: (object, options) ->

    @objectSubscriptionsByObject[object.getID()] = subscriptions = new CompositeDisposable

    subscriptions.add object.on('change', @onChangedObject)
    subscriptions.add object.on('remove', @onRemovedObject)

    @objectSubscriptions.add(subscriptions)
    @objects.push(object)
    @emitter.emit('change') unless @options?.silent

  setSize: (w, h) ->
    size = Size.create(w, h)
    return if size.equals(@size)
    @size = size
    @emitter.emit 'change:size', {size}

  getSize: -> @size

  onChangedObject: (event) =>
    @emitter.emit 'change', event

  onRemovedObject: (event) =>
    {object} = event
    subscription = @objectSubscriptionsByObject[object.getID()]
    delete @objectSubscriptionsByObject[object.getID()]
    if subscription?
      subscription.dispose()
      @objectSubscriptions.remove(subscription)
    index = @objects.indexOf(object)
    @objects.splice(index, 1) if index > -1
    @emitter.emit 'change', event
