SVGDocument = require '../src/svg-document'
Node = require '../src/node'
Path = require '../src/path'
PathEditor = require '../src/path-editor'

describe 'PathEditor', ->
  [svgDocument, canvas, path, editor] = []
  beforeEach ->
    canvas = document.createElement('div')
    jasmine.attachToDOM(canvas)
    svgDocument = new SVGDocument(canvas)

  beforeEach ->
    editor = new PathEditor(svgDocument)
    path = new Path(svgDocument)
    path.addNode(new Node([50, 50], [-10, 0], [10, 0]))
    path.close()

  it 'creates nodes when selecting and cleans up when selecting nothing', ->
    editor.activateObject(path)
    expect(canvas.querySelector('svg circle.node-editor-node')).toShow()
    expect(canvas.querySelector('svg path.object-selection')).toShow()

    editor.deactivate()
    expect(canvas.querySelector('svg circle.node-editor-node')).toHide()
    expect(canvas.querySelector('svg path.object-selection')).toBe null

  it 'renders node editor when selecting a node', ->
    editor.activateObject(path)
    editor.activateNode(path.getSubpaths()[0].nodes[0])

    expect(canvas.querySelectorAll('svg circle.node-editor-handle')[0]).toShow()
    expect(canvas.querySelectorAll('svg circle.node-editor-handle')[1]).toShow()
    expect(canvas.querySelectorAll('svg circle.node-editor-handle')[0]).toHaveAttr 'cx', '40'
    expect(canvas.querySelectorAll('svg circle.node-editor-handle')[1]).toHaveAttr 'cx', '60'

    editor.deactivateNode()

    expect(canvas.querySelectorAll('svg circle.node-editor-handle')[0]).toHide()
    expect(canvas.querySelectorAll('svg circle.node-editor-handle')[1]).toHide()

  it 'hides handles when unselecting object', ->
    editor.activateObject(path)
    editor.activateNode(path.getSubpaths()[0].nodes[0])

    expect(canvas.querySelectorAll('svg circle.node-editor-handle')[0]).toShow()
    expect(canvas.querySelectorAll('svg circle.node-editor-handle')[1]).toShow()

    editor.deactivate()

    expect(canvas.querySelectorAll('svg circle.node-editor-handle')[0]).toHide()
    expect(canvas.querySelectorAll('svg circle.node-editor-handle')[1]).toHide()

  it 'makes new NodeEditors when adding nodes to object', ->
    editor.activateObject(path)

    expect(canvas.querySelectorAll('svg circle.node-editor-node')).toHaveLength 1

    path.addNode(new Node([40, 40], [-10, 0], [10, 0]))
    expect(canvas.querySelectorAll('svg circle.node-editor-node')).toHaveLength 2

    path.addNode(new Node([10, 40], [-10, 0], [10, 0]))
    expect(canvas.querySelectorAll('svg circle.node-editor-node')).toHaveLength 3

  it 'removes NodeEditors when removing nodes from object', ->
    editor.activateObject(path)
    path.addNode(new Node([40, 40], [-10, 0], [10, 0]))
    path.addNode(new Node([10, 40], [-10, 0], [10, 0]))

    expect(editor.nodeEditors).toHaveLength 3

    path.removeNode(path.getNodes()[0])
    expect(editor.nodeEditors).toHaveLength 2

    path.removeNode(path.getNodes()[0])
    expect(editor.nodeEditors).toHaveLength 1

  it "emits an event when a node is mousedown'd", ->
    editor.activateObject(path)
    editor.activateNode(path.getNodes()[0])

    editor.on('mousedown:node', nodeSpy = jasmine.createSpy())

    nodeEditorElement = editor.nodeEditors[0].nodeElement.node
    xyParams = jasmine.buildMouseParams(20, 30)
    nodeEditorElement.dispatchEvent(jasmine.buildMouseEvent('mousedown', xyParams, target: nodeEditorElement))

    args = nodeSpy.calls.mostRecent().args[0]
    expect(nodeSpy).toHaveBeenCalled()
    expect(args.node).toBe path.getNodes()[0]
    expect(args.event).toBeTruthy()

    nodeEditorElement.dispatchEvent(jasmine.buildMouseEvent('mouseup', xyParams))

    path.addNode(new Node([10, 40], [-10, 0], [10, 0]))

    nodeEditorElement = editor.nodeEditors[1].nodeElement.node
    xyParams = jasmine.buildMouseParams(10, 40)
    nodeEditorElement.dispatchEvent(jasmine.buildMouseEvent('mousedown', xyParams, target: nodeEditorElement))

    args = nodeSpy.calls.mostRecent().args[0]
    expect(nodeSpy).toHaveBeenCalled()
    expect(args.node).toBe path.getNodes()[1]
