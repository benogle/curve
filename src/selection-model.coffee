{Emitter, CompositeDisposable} = require 'event-kit'

# Models what is selected and preselected. Preselection is shown as a red
# outline when the user hovers over the object.
module.exports =
class SelectionModel
  constructor: ->
    @emitter = new Emitter
    @preselected = null
    @selected = null
    @selectedNode = null

  on: (args...) -> @emitter.on(args...)

  getPreselected: -> @preselected

  setPreselected: (preselected) ->
    return if preselected == @preselected
    return if preselected and preselected == @selected
    old = @preselected
    @preselected = preselected
    @emitter.emit 'change:preselected', object: @preselected, old: old

  getSelected: -> @selected

  setSelected: (selected) ->
    return if selected == @selected
    old = @selected
    @selected = selected

    @selectedSubscriptions?.dispose()
    @selectedSubscriptions = null

    if @selected?
      @selectedSubscriptions = new CompositeDisposable
      @selectedSubscriptions.add @selected?.on('remove', => @setSelected(null)) if @selected.on?

    @setPreselected(null) if @preselected is selected
    @emitter.emit 'change:selected', object: @selected, old: old

  getSelectedNode: -> @selectedNode

  setSelectedNode: (selectedNode) ->
    return if selectedNode == @selectedNode
    old = @selectedNode
    @selectedNode = selectedNode
    @emitter.emit 'change:selectedNode', node: @selectedNode, old: old

  clearSelected: ->
    @setSelected(null)
  clearPreselected: ->
    @setPreselected(null)
  clearSelectedNode: ->
    @setSelectedNode(null)
