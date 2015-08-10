{Emitter} = require 'event-kit'
Rectangle = require '../src/rectangle'
SelectionModel = require '../src/selection-model'

describe 'SelectionModel', ->
  [model, path, onSelected, onSelectedNode] = []
  beforeEach ->
    model = new SelectionModel()
    path = {id: 1}

    model.on 'change:selected', onSelected = jasmine.createSpy()
    model.on 'change:selectedNode', onSelectedNode = jasmine.createSpy()

  it 'fires events when changing selection', ->
    model.setSelected(path)

    expect(onSelected).toHaveBeenCalled()
    expect(onSelected.calls.mostRecent().args[0]).toEqual object: path, old: null

  it 'fires events when changing selected node', ->
    node = {omg: 1}
    model.setSelectedNode(node)

    expect(onSelectedNode).toHaveBeenCalled()
    expect(onSelectedNode.calls.mostRecent().args[0]).toEqual node: node, old: null

  it 'sends proper old value through when unset', ->
    node = {omg: 1}
    model.setSelectedNode(node)
    model.setSelectedNode(null)

    expect(onSelectedNode).toHaveBeenCalled()
    expect(onSelectedNode.calls.mostRecent().args[0]).toEqual node: null, old: node

  it "deselects the object when it's been removed", ->
    emitter = new Emitter
    path.on = (args...) -> emitter.on(args...)

    model.setSelected(path)
    expect(model.getSelected()).toBe path

    emitter.emit('remove', {object: path})
    expect(model.getSelected()).toBe null
