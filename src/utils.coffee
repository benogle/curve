_ = window._ or require 'underscore'
$ = window.jQuery or require 'jquery'

Curve.Utils =
  getObjectFromNode: (domNode) ->
    $.data(domNode, 'curve.object')
  setObjectOnNode: (domNode, object) ->
    $.data(domNode, 'curve.object', object)
  pointForEvent: (svgDocument, event) ->
    {clientX, clientY} = event
    {top, left} = $(svgDocument.node).offset()
    new Curve.Point(event.clientX - left, event.clientY - top)
