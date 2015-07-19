Point = require "./point.coffee"

# Browserify loads this module twice :/
getObjectMap = ->
  g = (global ? window)
  g.NodeObjectMap ?= {}
  g.NodeObjectMap

Utils =
  getObjectFromNode: (domNode) ->
    getObjectMap()[domNode.id]

  setObjectOnNode: (domNode, object) ->
    getObjectMap()[domNode.id] = object

  pointForEvent: (svgDocument, event) ->
    {clientX, clientY} = event
    top = @svgDocument.node.offsetTop
    left = @svgDocument.node.offsetLeft
    new Point(event.clientX - left, event.clientY - top)

module.exports = Utils
