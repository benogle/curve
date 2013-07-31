{EventEmitter} = require 'events'

_ = require 'underscore'

#
module.exports =
class SelectionModel extends EventEmitter
  constructor: ->
    @preselected = null
    @selected = null
    @selectedNode = null

  setPreselected: (preselected) ->
    return if preselected == @preselected
    return if preselected == @selected
    old = @preselected
    @preselected = preselected
    @emit 'change:preselected', object: @preselected, old: old

  setSelected: (selected) ->
    return if selected == @selected
    old = @selected
    @selected = selected
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

_.extend(window.Curve, {SelectionModel})
