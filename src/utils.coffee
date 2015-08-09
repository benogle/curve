Point = require "./point"

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

  pointForEvent: (svgRoot, event) ->
    {clientX, clientY} = event
    top = @svgRoot.node.offsetTop
    left = @svgRoot.node.offsetLeft
    new Point(event.clientX - left, event.clientY - top)

module.exports = Utils
