ObjectSelection = require "./object-selection"

# Handles showing / hiding the red outlines when an object is preselected. This
# handles preselection only. Each ObjectEditor (e.g. PathEditor, ShapeEditor)
# handles displaying its own selection rect or path.
module.exports =
class SelectionView
  constructor: (@svgDocument) ->
    @model = @svgDocument.getSelectionModel()
    @objectPreselection = new ObjectSelection(@svgDocument, class: 'object-preselection')
    @model.on 'change:preselected', @onChangePreselected

  getObjectSelection: ->
    @objectSelection

  onChangePreselected: ({object}) =>
    @objectPreselection.setObject(object)
