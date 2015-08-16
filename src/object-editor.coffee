{CompositeDisposable} = require 'event-kit'
PathEditor = require './path-editor'
ShapeEditor = require './shape-editor'

# Manages the editor UIs for all object types. e.g. PathEditor object for <path>
# SVG objects.
#
# The goal for this arch is flexibility. Any tool can make one of these and
# activate it when it wants UIs for object editing.
module.exports =
class ObjectEditor
  constructor: (@svgDocument) ->
    @active = false
    @activeEditor = null
    @selectionModel = @svgDocument.getSelectionModel()
    @editors =
      Path: new PathEditor(@svgDocument)
      Rectangle: new ShapeEditor(@svgDocument)

  isActive: ->
    @active

  getActiveObject: ->
    @activeEditor?.getActiveObject() ? null

  getActiveEditor: ->
    @activeEditor

  activate: ->
    @active = true
    @subscriptions = new CompositeDisposable
    @subscriptions.add @selectionModel.on('change:selected', ({object}) => @activateSelectedObject(object))
    @subscriptions.add @selectionModel.on('change:selectedNode', ({node}) => @activateSelectedNode(node))
    @activateSelectedObject(@selectionModel.getSelected())
    @activateSelectedNode(@selectionModel.getSelectedNode())

  deactivate: ->
    @subscriptions?.dispose()
    @_deactivateActiveEditor()
    @active = false

  activateSelectedObject: (object) =>
    @_deactivateActiveEditor()
    if object?
      @activeEditor = @editors[object.getType()]
      @activeEditor?.activateObject(object)

  activateSelectedNode: (node) =>
    @activeEditor?.activateNode?(node)

  _deactivateActiveEditor: ->
    @activeEditor?.deactivate()
    @activeEditor = null
