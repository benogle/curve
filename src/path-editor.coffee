{Emitter, CompositeDisposable} = require 'event-kit'
Delegator = require 'delegato'
NodeEditor = require './node-editor'

# Handles the UI for free-form path editing. Manages NodeEditor objects based on
# a Path's nodes.
module.exports =
class PathEditor
  Delegator.includeInto(this)
  @delegatesMethods 'on', toProperty: 'emitter'

  constructor: (@svgDocument) ->
    @emitter = new Emitter
    @path = null
    @node = null
    @nodeEditors = []
    @_nodeEditorPool = []
    @nodeEditorSubscriptions = new CompositeDisposable()

  isActive: -> !!@path

  getActiveObject: -> @path

  activateObject: (object) ->
    @deactivate()
    if object?
      @path = object
      @_bindToObject(@path)
      @_createNodeEditors(@path)

  deactivate: ->
    @deactivateNode()
    @_unbindFromObject()
    @_removeNodeEditors()
    @path = null

  activateNode: (node) ->
    @deactivateNode()
    if node?
      @activeNode = node
      nodeEditor = @_findNodeEditorForNode(node)
      nodeEditor.setEnableHandles(true) if nodeEditor?

  deactivateNode: ->
    if @activeNode?
      nodeEditor = @_findNodeEditorForNode(@activeNode)
      nodeEditor.setEnableHandles(false) if nodeEditor?
    @activeNode = null

  onInsertNode: ({node, index}={}) =>
    @_addNodeEditor(node)
    null # Force null. otherwise _insertNodeEditor returns true and tells event emitter 'once'. Ugh

  _bindToObject: (object) ->
    return unless object
    @objectSubscriptions = new CompositeDisposable
    @objectSubscriptions.add object.on('insert:node', @onInsertNode)

  _unbindFromObject: ->
    @objectSubscriptions?.dispose()
    @objectSubscriptions = null

  _removeNodeEditors: ->
    @_nodeEditorPool = @_nodeEditorPool.concat(@nodeEditors)
    @nodeEditors = []
    for nodeEditor in @_nodeEditorPool
      nodeEditor.setNode(null)
    return

  _createNodeEditors: (object) ->
    @_removeNodeEditors()

    if object?.getNodes?
      nodes = object.getNodes()
      @_addNodeEditor(node) for node in nodes
    return

  _addNodeEditor: (node) ->
    return false unless node

    if @_nodeEditorPool.length
      nodeEditor = @_nodeEditorPool.pop()
    else
      nodeEditor = new NodeEditor(@svgDocument, this)
      @nodeEditorSubscriptions.add nodeEditor.on 'mousedown:node', @_forwardEvent.bind(this, 'mousedown:node')

    nodeEditor.setNode(node)
    @nodeEditors.push(nodeEditor)
    true

  _findNodeEditorForNode: (node) ->
    for nodeEditor in @nodeEditors
      return nodeEditor if nodeEditor.node == node
    null

  _forwardEvent: (eventName, args) ->
    return unless path = @getActiveObject()
    args.object = path
    @emitter.emit(eventName, args)
