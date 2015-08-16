Point = require "./point"
Size = require "./size"

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

  normalizePositionAndSize: (anchor, point) ->
    topLeft = new Point(Math.min(anchor.x, point.x), Math.min(anchor.y, point.y))
    bottomRight = new Point(Math.max(anchor.x, point.x), Math.max(anchor.y, point.y))
    diff = bottomRight.subtract(topLeft)
    {position: topLeft, size: new Size(diff.x, diff.y)}

module.exports = Utils
