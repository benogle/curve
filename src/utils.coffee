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

  getCanvasPosition: (svgRoot, event) ->
    if event.offsetX? and event.offsetY?
      x = event.offsetX
      y = event.offsetY
    else
      x = event.pageX - svgRoot.node.offsetLeft
      y = event.pageY - svgRoot.node.offsetTop
    new Point(x, y)

module.exports = Utils
