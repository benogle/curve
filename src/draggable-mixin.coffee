Mixin = require 'mixto'

module.exports =
class Draggable extends Mixin
  # Allows for user dragging on the screen
  # * `startEvent` (optional) event from a mousedown event
  enableDragging: (startEvent) ->
    return if @_draggingEnabled
    element = @svgEl
    return unless element?

    element.draggable(startEvent)
    element.dragmove = =>
      @updateFromAttributes()
    element.dragend = (event) =>
      @model.set(transform: null)
      @model.translate([event.x, event.y])
    @_draggingEnabled = true

  disableDragging: ->
    return unless @_draggingEnabled
    element = @svgEl
    return unless element?

    element.fixed?()
    element.dragstart = null
    element.dragmove = null
    element.dragend = null
    @_draggingEnabled = false
