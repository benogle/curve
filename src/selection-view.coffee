_ = require 'underscore'

require './node-editor'
ObjectSelection = require './object-selection'

#
module.exports =
class SelectionView
  nodeSize: 5

  constructor: (@model) ->
    @path = null
    @nodeEditors = []
    @_nodeEditorStash = []

    @objectSelection = new ObjectSelection()
    @objectPreselection = new ObjectSelection(class: 'object-preselection')

    @model.on 'change:selected', @onChangeSelected
    @model.on 'change:preselected', @onChangePreselected
    @model.on 'change:selectedNode', @onChangeSelectedNode

  onChangeSelected: ({object, old}) =>
    @_unbindFromObject(old)
    @_bindToObject(object)
    @setSelectedObject(object)
  onChangePreselected: ({object}) =>
    @objectPreselection.setObject(object)
  onChangeSelectedNode: ({node, old}) =>
    nodeEditor = @_findNodeEditorForNode(old)
    nodeEditor.setEnableHandles(false) if nodeEditor

    nodeEditor = @_findNodeEditorForNode(node)
    nodeEditor.setEnableHandles(true) if nodeEditor

  setSelectedObject: (object) ->
    @objectSelection.setObject(object)
    @_createNodeEditors(object)

  onInsertNode: (object, {node, index}={}) =>
    @_insertNodeEditor(object, index)
    null # Force null. _insertNodeEditor returns true and tells event emitter 'once'. Ugh

  _bindToObject: (object) ->
    return unless object
    object.on 'insert:node', @onInsertNode

  _unbindFromObject: (object) ->
    return unless object
    object.removeListener 'insert:node', @onInsertNode

  _createNodeEditors: (object) ->
    @_nodeEditorStash = @nodeEditors
    @nodeEditors = []

    if object
      for i in [0...object.nodes.length]
        @_insertNodeEditor(object, i)

    for nodeEditor in @_nodeEditorStash
      nodeEditor.setNode(null)

  _insertNodeEditor: (object, index) ->
    return false unless object and object.nodes[index]

    nodeEditor = if @_nodeEditorStash.length
      @_nodeEditorStash.pop()
    else
      new window.Curve.NodeEditor(@model)

    nodeEditor.setNode(object.nodes[index])
    @nodeEditors.splice(index, 0, nodeEditor)
    true

  _findNodeEditorForNode: (node) ->
    for nodeEditor in @nodeEditors
      return nodeEditor if nodeEditor.node == node
    null

_.extend(window.Curve, {SelectionView})
