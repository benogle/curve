
#
class Curve.SelectionView
  nodeSize: 5

  constructor: (@svgDocument, @model) ->
    @path = null
    @nodeEditors = []
    @_nodeEditorStash = []

    @objectSelection = new Curve.ObjectSelection(@svgDocument)
    @objectPreselection = new Curve.ObjectSelection(@svgDocument, class: 'object-preselection')

    @model.on 'change:selected', @onChangeSelected
    @model.on 'change:preselected', @onChangePreselected
    @model.on 'change:selectedNode', @onChangeSelectedNode

  getObjectSelection: -> @objectSelection

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
    @_addNodeEditor(node)
    null # Force null. otherwise _insertNodeEditor returns true and tells event emitter 'once'. Ugh

  _bindToObject: (object) ->
    return unless object
    object.on 'insert:node', @onInsertNode

  _unbindFromObject: (object) ->
    return unless object
    object.removeListener 'insert:node', @onInsertNode

  _createNodeEditors: (object) ->
    @_nodeEditorStash = @_nodeEditorStash.concat(@nodeEditors)
    @nodeEditors = []

    if object
      nodes = object.getNodes()
      @_addNodeEditor(node) for node in nodes

    for nodeEditor in @_nodeEditorStash
      nodeEditor.setNode(null)

  _addNodeEditor: (node) ->
    return false unless node

    nodeEditor = if @_nodeEditorStash.length
      @_nodeEditorStash.pop()
    else
      new Curve.NodeEditor(@svgDocument, @model)

    nodeEditor.setNode(node)
    @nodeEditors.push(nodeEditor)
    true

  _findNodeEditorForNode: (node) ->
    for nodeEditor in @nodeEditors
      return nodeEditor if nodeEditor.node == node
    null
