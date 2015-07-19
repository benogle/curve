require './ext/svg.circle.coffee'
require './ext/svg.draggable.coffee'
require './ext/svg.export.coffee'

module.exports = {
  Point: require "./point.coffee"
  Size: require "./size.coffee"
  Transform: require "./transform.coffee"
  Utils: require "./utils.coffee"

  Node: require "./node.coffee"

  Path: require "./path.coffee"
  Subpath: require "./subpath.coffee"
  Rectangle: require "./rectangle.coffee"

  NodeEditor: require "./node-editor.coffee"
  ObjectEditor: require "./object-editor.coffee"
  ObjectSelection: require "./object-selection.coffee"
  PathEditor: require "./path-editor.coffee"
  PathParser: require "./path-parser.coffee"

  SelectionModel: require "./selection-model.coffee"
  SelectionView: require "./selection-view.coffee"

  PenTool: require "./pen-tool.coffee"
  PointerTool: require "./pointer-tool.coffee"

  SVGDocument: require "./svg-document.coffee"
}
