EventEmitter = window.EventEmitter or require('events').EventEmitter

# Models what is selected and preselected. Preselection is shown as a red
# outline when the user hovers over the object.
class Curve.SelectionModel extends EventEmitter
  constructor: ->
    @preselected = null
    @selected = null
    @selectedNode = null

  setPreselected: (preselected) ->
    return if preselected == @preselected
    return if preselected and preselected == @selected
    old = @preselected
    @preselected = preselected
    @emit 'change:preselected', object: @preselected, old: old

  setSelected: (selected) ->
    return if selected == @selected
    old = @selected
    @selected = selected
    @setPreselected(null) if @preselected is selected
    @emit 'change:selected', object: @selected, old: old

  setSelectedNode: (selectedNode) ->
    return if selectedNode == @selectedNode
    old = @selectedNode
    @selectedNode = selectedNode
    @emit 'change:selectedNode', node: @selectedNode, old: old

  clearSelected: ->
    @setSelected(null)
  clearPreselected: ->
    @setPreselected(null)
  clearSelectedNode: ->
    @setSelectedNode(null)
