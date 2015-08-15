{CompositeDisposable} = require 'event-kit'
PathEditor = require './path-editor'

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

  isActive: ->
    @active

  getActiveObject: ->
    @activeEditor?.getActiveObject() ? null

  getActiveEditor: ->
    @activeEditor

  activate: ->
    @active = true
    @subscriptions = new CompositeDisposable
    @subscriptions.add @selectionModel.on('change:selected', @onChangeSelected)
    @subscriptions.add @selectionModel.on('change:selectedNode', @onChangeSelectedNode)

  deactivate: ->
    @subscriptions?.dispose()
    @_deactivateActiveEditor()
    @active = false

  onChangeSelected: ({object}) =>
    @_deactivateActiveEditor()
    if object?
      @activeEditor = @editors[object.getType()]
      @activeEditor?.activateObject(object)

  onChangeSelectedNode: ({node}) =>
    @activeEditor?.activateNode?(node)

  _deactivateActiveEditor: ->
    @activeEditor?.deactivate()
    @activeEditor = null
