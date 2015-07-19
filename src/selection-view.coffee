ObjectSelection = require "./object-selection.coffee"

# Handles showing / hiding the red and blue outlines when an object is selected /
# preselected.

module.exports =
class SelectionView
  constructor: (@svgDocument, @model) ->
    @objectSelection = new ObjectSelection(@svgDocument)
    @objectPreselection = new ObjectSelection(@svgDocument, class: 'object-preselection')
    @model.on 'change:selected', @onChangeSelected
    @model.on 'change:preselected', @onChangePreselected

  getObjectSelection: ->
    @objectSelection

  onChangeSelected: ({object, old}) =>
    @objectSelection.setObject(object)

  onChangePreselected: ({object}) =>
    @objectPreselection.setObject(object)
