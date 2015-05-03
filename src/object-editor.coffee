# Manages the editor UIs for all object types. e.g. PathEditor object for <path>
# SVG objects.
#
# The goal for this arch is flexibility. Any tool can make one of these and
# activate it when it wants UIs for object editing.
class Curve.ObjectEditor
  constructor: (@svgDocument, @selectionModel) ->
    @active = false
    @activeEditor = null
    @editors =
      Path: new Curve.PathEditor(@svgDocument)

  isActive: ->
    @active

  getActiveObject: ->
    @activeEditor?.getActiveObject() ? null

  activate: ->
    @active = true
    @selectionModel.on 'change:selected', @onChangeSelected

  deactivate: ->
    @selectionModel.removeListener 'change:selected', @onChangeSelected
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
