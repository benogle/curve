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

  activate: ->
    @active = true
    @subscriptions = new CompositeDisposable
    @subscriptions.add @selectionModel.on('change:selected', @onChangeSelected)

  deactivate: ->
    @subscriptions?.dispose()
    @_deactivateActiveEditor()
    @active = false

  onChangeSelected: ({object, old}) =>
    @_deactivateActiveEditor()
    if object?
      @activeEditor = @editors[object.getType()]
      @activeEditor?.activateObject(object)

  _deactivateActiveEditor: ->
    @activeEditor?.deactivate()
    @activeEditor = null
