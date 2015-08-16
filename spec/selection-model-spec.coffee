{Emitter} = require 'event-kit'
SelectionModel = require '../src/selection-model'

SVGDocument = require '../src/svg-document'
Node = require '../src/node'
Path = require '../src/path'

describe 'SelectionModel', ->
  [model, path, onSelected, onSelectedNode, svg] = []
  beforeEach ->
    canvas = document.createElement('div')
    svg = new SVGDocument(canvas)

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

  it "deselects the node when it's been removed", ->
    path = new Path(svg)
    path.addNode(new Node([50, 50]))
    path.addNode(new Node([80, 60]))
    path.addNode(new Node([60, 80]))

    node = path.getNodes()[1]
    model.setSelected(path)
    model.setSelectedNode(node)
    expect(model.getSelected()).toBe path
    expect(model.getSelectedNode()).toBe node

    path.removeNode(path.getNodes()[0])
    expect(model.getSelected()).toBe path
    expect(model.getSelectedNode()).toBe node

    path.removeNode(node)
    expect(model.getSelected()).toBe path
    expect(model.getSelectedNode()).toBe null
