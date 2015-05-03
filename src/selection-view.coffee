# Handles showing / hiding the red and blue outlines when an object is selected /
# preselected.
class Curve.SelectionView
  constructor: (@svgDocument, @model) ->
    @objectSelection = new Curve.ObjectSelection(@svgDocument)
    @objectPreselection = new Curve.ObjectSelection(@svgDocument, class: 'object-preselection')
    @model.on 'change:selected', @onChangeSelected
    @model.on 'change:preselected', @onChangePreselected

  getObjectSelection: ->
    @objectSelection

  onChangeSelected: ({object, old}) =>
    @objectSelection.setObject(object)

  onChangePreselected: ({object}) =>
    @objectPreselection.setObject(object)
