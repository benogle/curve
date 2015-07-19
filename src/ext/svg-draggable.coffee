# svg.draggable.js 0.1.0 - Copyright (c) 2014 Wout Fierens - Licensed under the MIT license
# extended by Florian Loch
#
# Modified by benogle
# * It's now using translations for moves, rather than the move() method
# * I removed a bunch of features I didnt need

SVG = require '../../vendor/svg'

TranslateRegex = /translate\(([-0-9]+) ([-0-9]+)\)/

SVG.extend SVG.Element, draggable: ->
  element = this
  @fixed?() # remove draggable if already present

  startHandler = (event) ->
    onStart(element, event)
    attachDragEvents(dragHandler, endHandler)
  dragHandler = (event) ->
    onDrag(element, event)
  endHandler = (event) ->
    onEnd(element, event)
    detachDragEvents(dragHandler, endHandler)

  element.on 'mousedown', startHandler

  # Disable dragging on this event.
  element.fixed = ->
    element.off 'mousedown', startHandler
    detachDragEvents()
    startHandler = dragHandler = endHandler = null
    element
  this

attachDragEvents = (dragHandler, endHandler) ->
  SVG.on window, 'mousemove', dragHandler
  SVG.on window, 'mouseup', endHandler

detachDragEvents = (dragHandler, endHandler) ->
  SVG.off window, 'mousemove', dragHandler
  SVG.off window, 'mouseup', endHandler

onStart = (element, event=window.event) ->
  parent = element.parent._parent(SVG.Nested) or element._parent(SVG.Doc)
  element.startEvent = event

  x = y = 0
  translation = TranslateRegex.exec(element.attr('transform'))
  if translation?
    x = parseInt(translation[1])
    y = parseInt(translation[2])

  zoom = parent.viewbox().zoom
  rotation = element.transform('rotation') * Math.PI / 180
  element.startPosition = {x, y, zoom, rotation}
  element.dragstart?({x: 0, y: 0, zoom}, event)

  ### prevent selection dragging ###
  if event.preventDefault then event.preventDefault() else (event.returnValue = false)

onDrag = (element, event=window.event) ->
  if element.startEvent
    rotation = element.startPosition.rotation
    delta =
      x: event.pageX - element.startEvent.pageX
      y: event.pageY - element.startEvent.pageY
      zoom: element.startPosition.zoom

    ### caculate new position [with rotation correction] ###
    x = element.startPosition.x + (delta.x * Math.cos(rotation) + delta.y * Math.sin(rotation)) / element.startPosition.zoom
    y = element.startPosition.y + (delta.y * Math.cos(rotation) + delta.x * Math.sin(-rotation)) / element.startPosition.zoom

    element.transform({x, y})
    element.dragmove?(delta, event)

onEnd = (element, event=window.event) ->
  delta =
    x: event.pageX - element.startEvent.pageX
    y: event.pageY - element.startEvent.pageY
    zoom: element.startPosition.zoom

  element.startEvent = null
  element.startPosition = null
  element.dragend?(delta, event)
