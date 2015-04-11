Curve = {}

if typeof module != 'undefined'
  module.exports = Curve
else
  window.Curve = Curve

SVG = window.SVG or require('./vendor/svg').SVG

#
class SVG.Circle extends SVG.Shape
  constructor: ->
    super(SVG.create('circle'))

  cx: (x) ->
    if x == null then this.attr('cx') else @attr('cx', new SVG.Number(x).divide(this.trans.scaleX))

  cy: (y) ->
    if y == null then this.attr('cy') else @attr('cy', new SVG.Number(y).divide(this.trans.scaleY))

  radius: (rad) ->
    @attr(r: new SVG.Number(rad))


SVG.extend SVG.Container,
  circle: (radius) ->
    return this.put(new SVG.Circle).radius(radius).move(0, 0)

# svg.draggable.js 0.1.0 - Copyright (c) 2014 Wout Fierens - Licensed under the MIT license
# extended by Florian Loch
#
# Modified by benogle
# * It's now using translations for moves, rather than the move() method
# * I removed a bunch of features I didnt need

TranslateRegex = /translate\(([-0-9]+) ([-0-9]+)\)/

SVG.extend SVG.Element, draggable: ->
  element = this
  @fixed?() # remove draggable if already present

  startHandler = (event) ->
    onStart(element, event)
    attachDragEvents(dragHandler, endHandler)
  dragHandler = (event) ->
    onDrag(element, event)
  endHandler = (event) ->
    onEnd(element, event)
    detachDragEvents(dragHandler, endHandler)

  element.on 'mousedown', startHandler

  # Disable dragging on this event.
  element.fixed = ->
    element.off 'mousedown', startHandler
    detachDragEvents()
    startHandler = dragHandler = endHandler = null
    element
  this

attachDragEvents = (dragHandler, endHandler) ->
  SVG.on window, 'mousemove', dragHandler
  SVG.on window, 'mouseup', endHandler

detachDragEvents = (dragHandler, endHandler) ->
  SVG.off window, 'mousemove', dragHandler
  SVG.off window, 'mouseup', endHandler

onStart = (element, event=window.event) ->
  parent = element.parent._parent(SVG.Nested) or element._parent(SVG.Doc)
  element.startEvent = event

  x = y = 0
  translation = TranslateRegex.exec(element.attr('transform'))
  if translation?
    x = parseInt(translation[1])
    y = parseInt(translation[2])

  zoom = parent.viewbox().zoom
  rotation = element.transform('rotation') * Math.PI / 180
  element.startPosition = {x, y, zoom, rotation}
  element.dragstart?({x: 0, y: 0, zoom}, event)

  ### prevent selection dragging ###
  if event.preventDefault then event.preventDefault() else (event.returnValue = false)

onDrag = (element, event=window.event) ->
  if element.startEvent
    rotation = element.startPosition.rotation
    delta =
      x: event.pageX - element.startEvent.pageX
      y: event.pageY - element.startEvent.pageY
      zoom: element.startPosition.zoom

    ### caculate new position [with rotation correction] ###
    x = element.startPosition.x + (delta.x * Math.cos(rotation) + delta.y * Math.sin(rotation)) / element.startPosition.zoom
    y = element.startPosition.y + (delta.y * Math.cos(rotation) + delta.x * Math.sin(-rotation)) / element.startPosition.zoom

    element.transform({x, y})
    element.dragmove?(delta, event)

onEnd = (element, event=window.event) ->
  delta =
    x: event.pageX - element.startEvent.pageX
    y: event.pageY - element.startEvent.pageY
    zoom: element.startPosition.zoom

  element.startEvent = null
  element.startPosition = null
  element.dragend?(delta, event)

SVG = window.SVG or require('./vendor/svg').SVG

# svg.export.js 0.8 - Copyright (c) 2013 Wout Fierens - Licensed under the MIT license
#
# Coffeescript'd and modified by benogle
#
# This walks the SVG nodes, and stringifies them.
SVG.extend SVG.Element,
  # Build node string
  export: (options, level) ->
    name = this.node.nodeName
    node = ''

    isRootSvgElement = name == 'svg' and not level

    # ensure options
    options = options || {}

    if !options.exclude || !options.exclude.call(this)
      # ensure defaults
      options = options || {}
      level = level || 0

      # set context
      if isRootSvgElement
        # define doctype
        node += this._whitespaced('<?xml version="1.0" encoding="UTF-8"?>', options.whitespace, level)

        # store current width and height
        width  = this.attr('width')
        height = this.attr('height')

        # set required size
        if options.width
          this.attr('width', options.width)
        if options.height
          this.attr('height', options.height)

      # open node
      node += this._whitespaced('<' + name + this.attrToString() + '>', options.whitespace, level)

      # reset size and add description
      if isRootSvgElement
        this.attr
          width:  width
          height: height

        # add description
        node += this._whitespaced('<desc>Created with Curve</desc>', options.whitespace, level + 1)

        if this._defs
          # add defs
          node += this._whitespaced('<defs>', options.whitespace, level + 1)
          for i in [0...this._defs.children().length]
            node += this._defs.children()[i].export(options, level + 2)
          node += this._whitespaced('</defs>', options.whitespace, level + 1)

      # add children
      if this instanceof SVG.Container
        for i in [0...this.children().length]
          node += this.children()[i].export(options, level + 1)

      else if this instanceof SVG.Text
        for i in [0...this.lines.length]
          node += this.lines[i].export(options, level + 1)

      # add tspan content
      if this instanceof SVG.TSpan
        node += this._whitespaced(this.node.firstChild.nodeValue, options.whitespace, level + 1)

      # close node
      node += this._whitespaced('</' + name + '>', options.whitespace, level)

    node

  # Set specific export attibutes
  exportAttr: (attr) ->
    return this.data('svg-export-attr') if arguments.length == 0
    this.data('svg-export-attr', attr)

  # Convert attributes to string
  attrToString: ->
    attr = []
    data = this.exportAttr()
    exportAttrs = this.attr()

    # ensure data
    if typeof data == 'object'
      for key of data
        if key != 'data-svg-export-attr'
          exportAttrs[key] = data[key]

    # build list
    for key of exportAttrs
      value = exportAttrs[key]

      # enfoce explicit xlink namespace
      key = 'xmlns:xlink' if key == 'xlink'

      isGeneratedId = key == 'id' and value.indexOf('Svgjs') > -1
      if not isGeneratedId and key != 'data-svg-export-attr' and (key != 'stroke' or parseFloat(exportAttrs['stroke-width']) > 0)
        attr.push(key + '="' + value + '"')

    if attr.length then ' ' + attr.join(' ') else ''

  # Whitespaced string
  _whitespaced: (value, add, level) ->
    if add
      whitespace = ''
      space = if add == true then '  ' else add or ''

      # build indentation
      if level
        for i in [level-1..0]
          whitespace += space

      # add whitespace
      value = whitespace + value + '\n'

    value

# svg.import.js 0.11 - Copyright (c) 2013 Wout Fierens - Licensed under the MIT license
#
# Converted to coffeescript and modified by benogle

# Place the `svgString` in the svgDocument, and parse into objects Curve can
# understand
#
# * `svgDocument` An empty {SVG} document
# * `svgString` {String} with the svg markup
#
# Returns an array of objects selectable and editable by Curve tools.
Curve.import = (svgDocument, svgString) ->
  IMPORT_FNS =
    path: (el) -> [new Curve.Path(svgDocument, svgEl: el)]

  # create temporary div to receive svg content
  parentNode = document.createElement('div')
  store = {}

  # properly close svg tags and add them to the DOM
  parentNode.innerHTML = svgString
    .replace(/\n/, '')
    .replace(/<(\w+)([^<]+?)\/>/g, '<$1$2></$1>')

  objects = []
  convertNodes parentNode.childNodes, svgDocument, 0, store, ->
    nodeType = this.node.nodeName
    objects = objects.concat(IMPORT_FNS[nodeType](this)) if IMPORT_FNS[nodeType]
    null

  parentNode = null
  objects

# Convert nodes to svg.js elements
convertNodes = (nodes, context, level, store, block) ->
  for i in [0...nodes.length]
    child = nodes[i]
    attr  = {}
    clips = []

    # get node type
    type = child.nodeName.toLowerCase()

    #  objectify attributes
    attr = objectifyAttributes(child)

    # create elements
    switch type
      when 'path' then element = context[type]()
      when 'polygon' then element = context[type]()
      when 'polyline' then element = context[type]()

      when 'rect' then element = context[type](0,0)
      when 'circle' then element = context[type](0,0)
      when 'ellipse' then element = context[type](0,0)

      when 'line' then element = context.line(0,0,0,0)

      when 'text'
        if child.childNodes.length == 0
          element = context[type](child.textContent)
        else
          element = null

          for j in [0...child.childNodes.length]
            grandchild = child.childNodes[j]

            if grandchild.nodeName.toLowerCase() == 'tspan'
              if element == null
                # first time through call the text() function on the current context
                element = context[type](grandchild.textContent)
              else
                # for the remaining times create additional tspans
                element
                  .tspan(grandchild.textContent)
                  .attr(objectifyAttributes(grandchild))

      when 'image' then element = context.image(attr['xlink:href'])

      when 'g', 'svg'
        element = context[if type == 'g' then 'group' else 'nested']()
        convertNodes(child.childNodes, element, level + 1, store, block)

      when 'defs'
        convertNodes(child.childNodes, context.defs(), level + 1, store, block)

      when 'use'
        element = context.use()

      when 'clippath', 'mask'
        element = context[type == 'mask' ? 'mask' : 'clip']()
        convertNodes(child.childNodes, element, level + 1, store, block)

      when 'lineargradient', 'radialgradient'
        element = context.defs().gradient type.split('gradient')[0], (stop) ->
          for j in [0...child.childNodes.length]
            stop
              .at(objectifyAttributes(child.childNodes[j]))
              .style(child.childNodes[j].getAttribute('style'))

      when '#comment', '#text', 'metadata', 'desc'
        ; # safely ignore these elements
      else
        console.log('SVG Import got unexpected type ' + type, child)

    if element
      # parse transform attribute
      transform = objectifyTransformations(attr.transform)
      delete attr.transform

      # set attributes and transformations
      element
        .attr(attr)
        .transform(transform)

      # store element by id
      store[element.attr('id')] = element if element.attr('id')

      # now that we've set the attributes "rebuild" the text to correctly set the attributes
      element.rebuild() if type == 'text'

      # call block if given
      block.call(element) if typeof block == 'function'

  context

# Convert attributes to an object
objectifyAttributes = (child) ->
  attrs = child.attributes or []
  attr  = {}

  # gather attributes
  if attrs.length
    for i in [attrs.length-1..0]
      attr[attrs[i].nodeName] = attrs[i].nodeValue

  attr

# Convert transformations to an object
objectifyTransformations = (transform) ->
  trans = {}
  list  = (transform or '').match(/[A-Za-z]+\([^\)]+\)/g) || []
  def   = SVG.defaults.trans()

  # gather transformations
  if list.length
    for i in [list.length-1..0]
      # parse transformation
      t = list[i].match(/([A-Za-z]+)\(([^\)]+)\)/)
      v = (t[2] || '').replace(/^\s+/,'').replace(/,/g, ' ').replace(/\s+/g, ' ').split(' ')

      # objectify transformation
      switch t[1]
        when 'matrix'
          trans.a         = parseFloat(v[0]) || def.a
          trans.b         = parseFloat(v[1]) || def.b
          trans.c         = parseFloat(v[2]) || def.c
          trans.d         = parseFloat(v[3]) || def.d
          trans.e         = parseFloat(v[4]) || def.e
          trans.f         = parseFloat(v[5]) || def.f

        when 'rotate'
          trans.rotation  = parseFloat(v[0]) || def.rotation
          trans.cx        = parseFloat(v[1]) || def.cx
          trans.cy        = parseFloat(v[2]) || def.cy

        when 'scale'
          trans.scaleX    = parseFloat(v[0]) || def.scaleX
          trans.scaleY    = parseFloat(v[1]) || def.scaleY

        when 'skewX'
          trans.skewX     = parseFloat(v[0]) || def.skewX

        when 'skewY'
          trans.skewY     = parseFloat(v[0]) || def.skewY

        when 'translate'
          trans.x         = parseFloat(v[0]) || def.x
          trans.y         = parseFloat(v[1]) || def.y

  trans

# TODO: use browserify, and require this from:
# https://github.com/atom/mixto/blob/master/src/mixin.coffee
class Mixin
  @includeInto: (constructor) ->
    @extend(constructor.prototype)
    for name, value of this
      if ExcludedClassProperties.indexOf(name) is -1
        constructor[name] = value unless constructor.hasOwnProperty(name)
    @included?.call(constructor)

  @extend: (object) ->
    for name in Object.getOwnPropertyNames(@prototype)
      if ExcludedPrototypeProperties.indexOf(name) is -1
        object[name] = @prototype[name] unless object.hasOwnProperty(name)
    @prototype.extended?.call(object)

  constructor: ->
    @extended?()

ExcludedClassProperties = ['__super__']
ExcludedClassProperties.push(name) for name of Mixin
ExcludedPrototypeProperties = ['constructor', 'extended']

_ = window._ or require 'underscore'
$ = window.jQuery or require 'jquery'

# A node display in the interface allowing for user interaction (moving the
# node, moving the handles). Draws the node, and draws the handles.
class NodeEditor
  nodeSize: 5
  handleSize: 3

  node = null
  nodeElement = null
  handleElements = null
  lineElement = null

  constructor: (@svgToolParent, @selectionModel) ->
    @svgDocument = @svgToolParent.parent
    @_setupNodeElement()
    @_setupLineElement()
    @_setupHandleElements()
    @hide()

  hide: ->
    @visible = false
    @lineElement.hide()
    @nodeElement.hide()
    @handleElements.hide()

  show: (toFront) ->
    @visible = true
    @nodeElement.show()

    if toFront
      @lineElement.front()
      @nodeElement.front()
      @handleElements.front()

    if @enableHandles
      @lineElement.show()
      @handleElements.show()
    else
      @lineElement.hide()
      @handleElements.hide()

  setEnableHandles: (@enableHandles) ->
    @show() if @visible

  setNode: (node) ->
    @_unbindNode(@node)
    @node = node
    @_bindNode(@node)
    @setEnableHandles(false)
    @render()

  render: =>
    return @hide() unless @node

    handleIn = @node.getAbsoluteHandleIn()
    handleOut = @node.getAbsoluteHandleOut()
    point = @node.point

    linePath = "M#{handleIn.x},#{handleIn.y}L#{point.x},#{point.y}L#{handleOut.x},#{handleOut.y}"
    @lineElement.attr(d: linePath)

    @handleElements.members[0].attr(cx: handleIn.x, cy: handleIn.y)
    @handleElements.members[1].attr(cx: handleOut.x, cy: handleOut.y)

    @nodeElement.attr(cx: point.x, cy: point.y)

    @show()

    # make sure the handlethe user is dragging is on top. could get in the
    # situation where the handle passed under the other, and it feels weird.
    @_draggingHandle.front() if @_draggingHandle

  onDraggingNode: (delta, event) =>
    @node.setPoint(@pointForEvent(event))
  onDraggingHandleIn: (delta, event) =>
    @node.setAbsoluteHandleIn(@pointForEvent(event))
  onDraggingHandleOut: (delta, event) =>
    @node.setAbsoluteHandleOut(@pointForEvent(event))

  pointForEvent: (event) ->
    {clientX, clientY} = event
    {top, left} = $(@svgDocument.node).offset()
    new Curve.Point(event.clientX - left, event.clientY - top)

  _bindNode: (node) ->
    return unless node
    node.addListener 'change', @render
  _unbindNode: (node) ->
    return unless node
    node.removeListener 'change', @render

  _setupNodeElement: ->
    @nodeElement = @svgToolParent.circle(@nodeSize)
    @nodeElement.node.setAttribute('class', 'node-editor-node')

    @nodeElement.click (e) =>
      e.stopPropagation()
      @setEnableHandles(true)
      @selectionModel.setSelectedNode(@node)
      false

    @nodeElement.draggable()
    @nodeElement.dragstart = => @selectionModel.setSelectedNode(@node)
    @nodeElement.dragmove = @onDraggingNode
    @nodeElement.on 'mouseover', =>
      @nodeElement.front()
      @nodeElement.attr('r': @nodeSize+2)
    @nodeElement.on 'mouseout', =>
      @nodeElement.attr('r': @nodeSize)

  _setupLineElement: ->
    @lineElement = @svgToolParent.path('')
    @lineElement.node.setAttribute('class', 'node-editor-lines')

  _setupHandleElements: ->
    self = this

    @handleElements = @svgToolParent.set()
    @handleElements.add(
      @svgToolParent.circle(@handleSize),
      @svgToolParent.circle(@handleSize)
    )
    @handleElements.members[0].node.setAttribute('class', 'node-editor-handle')
    @handleElements.members[1].node.setAttribute('class', 'node-editor-handle')

    @handleElements.click (e) =>
      e.stopPropagation()
      false

    onStartDraggingHandle = ->
      self._draggingHandle = this
    onStopDraggingHandle = ->
      self._draggingHandle = null

    @handleElements.members[0].draggable()
    @handleElements.members[0].dragmove = @onDraggingHandleIn
    @handleElements.members[0].dragstart = onStartDraggingHandle
    @handleElements.members[0].dragend = onStopDraggingHandle

    @handleElements.members[1].draggable()
    @handleElements.members[1].dragmove = @onDraggingHandleOut
    @handleElements.members[1].dragstart = onStartDraggingHandle
    @handleElements.members[1].dragend = onStopDraggingHandle

    # I hate this.
    find = (el) =>
      return @handleElements.members[0] if @handleElements.members[0].node == el
      @handleElements.members[1]

    @handleElements.on 'mouseover', ->
      el = find(this)
      el.front()
      el.attr('r': self.handleSize+2)
    @handleElements.on 'mouseout', ->
      el = find(this)
      el.attr('r': self.handleSize)

Curve.NodeEditor = NodeEditor

_ = window._ or require 'underscore'

EventEmitter = window.EventEmitter or require('events').EventEmitter

#
class Node extends EventEmitter
  constructor: (point, handleIn, handleOut, @isJoined=false) ->
    @setPoint(point)
    @setHandleIn(handleIn) if handleIn
    @setHandleOut(handleOut) if handleOut

  join: (referenceHandle='handleIn') ->
    @isJoined = true
    @["set#{referenceHandle.replace('h', 'H')}"](@[referenceHandle])

  getPoint: -> @point
  getHandleIn: -> @handleIn
  getHandleOut: -> @handleOut

  getAbsoluteHandleIn: ->
    if @handleIn
      @point.add(@handleIn)
    else
      @point
  getAbsoluteHandleOut: ->
    if @handleOut
      @point.add(@handleOut)
    else
      @point

  setAbsoluteHandleIn: (point) ->
    @setHandleIn(Point.create(point).subtract(@point))
  setAbsoluteHandleOut: (point) ->
    @setHandleOut(Point.create(point).subtract(@point))

  setPoint: (point) ->
    @set('point', Point.create(point))
  setHandleIn: (point) ->
    point = Point.create(point) if point
    @set('handleIn', point)
    @set('handleOut', if point then new Curve.Point(0,0).subtract(point) else point) if @isJoined
  setHandleOut: (point) ->
    point = Point.create(point) if point
    @set('handleOut', point)
    @set('handleIn', if point then new Curve.Point(0,0).subtract(point) else point) if @isJoined

  computeIsjoined: ->
    @isJoined = (not @handleIn and not @handleOut) or (@handleIn and @handleOut and Math.round(@handleIn.x) == Math.round(-@handleOut.x) and Math.round(@handleIn.y) == Math.round(-@handleOut.y))

  set: (attribute, value) ->
    old = @[attribute]
    @[attribute] = value

    event = "change:#{attribute}"
    eventArgs = {event, value, old}

    @emit event, this, eventArgs
    @emit 'change', this, eventArgs

  translate: (point) ->
    point = Point.create(point)
    @set('point', @point.add(point))

Curve.Node = Node

EventEmitter = window.EventEmitter or require('events').EventEmitter

# The display for a selected object. i.e. the red or blue outline around the
# selected object.
#
# It basically cops the underlying object's attributes (path definition, etc.)
class Curve.ObjectSelection extends EventEmitter
  constructor: (@svgDocument, @options={}) ->
    @options.class ?= 'object-selection'

  setObject: (object) ->
    @_unbindObject(@object)
    old = object
    @object = object
    @_bindObject(@object)

    @path.remove() if @path
    @path = null
    if @object
      @path = @svgDocument.path('').back()
      @path.node.setAttribute('class', @options.class + ' invisible-to-hit-test')
      @render()
    @emit 'change:object', {objectSelection: this, @object, old}

  render: =>
    @object.render(@path)

  _bindObject: (object) ->
    return unless object
    object.on 'change', @render

  _unbindObject: (object) ->
    return unless object
    object.removeListener 'change', @render

_ = window._ or require 'underscore'

[COMMAND, NUMBER] = ['COMMAND', 'NUMBER']

parsePath = (pathString) ->
  #console.log 'parsing', pathString
  tokens = lexPath(pathString)
  parseTokens(groupCommands(tokens))

# Parses the result of lexPath
parseTokens = (groupedCommands) ->
  result = subpaths: []

  # Just a move command? We dont care.
  return result if groupedCommands.length == 1 and groupedCommands[0].type in ['M', 'm']

  # svg is stateful. Each command will set currentPoint.
  currentPoint = null
  currentSubpath = null
  addNewSubpath = (movePoint) ->
    node = new Node(movePoint)
    currentSubpath =
      closed: false
      nodes: [node]
    result.subpaths.push(currentSubpath)
    node

  slicePoint = (array, index) ->
    [array[index], array[index + 1]]

  # make relative points absolute based on currentPoint
  makeAbsolute = (array) ->
    _.map array, (val, i) ->
      val + currentPoint[i % 2]

  # Create a node and add it to the list. When the last node is the same as the
  # first, and the path is closed, we do not create the node.
  createNode = (point, commandIndex) ->
    currentPoint = point

    node = null
    firstNode = currentSubpath.nodes[0]

    nextCommand = groupedCommands[commandIndex + 1]
    unless nextCommand and nextCommand.type in ['z', 'Z'] and firstNode and firstNode.point.equals(currentPoint)
      node = new Node(currentPoint)
      currentSubpath.nodes.push(node)

    node

  for i in [0...groupedCommands.length]
    command = groupedCommands[i]
    switch command.type
      when 'M'
        # Move to
        currentPoint = command.parameters
        addNewSubpath(currentPoint)

      when 'L', 'l'
        # Line to
        params = command.parameters
        params = makeAbsolute(params) if command.type == 'l'
        createNode(slicePoint(params, 0), i)

      when 'H', 'h'
        # Horizontal line
        params = command.parameters
        params = makeAbsolute(params) if command.type == 'h'
        createNode([params[0], currentPoint[1]], i)

      when 'V', 'v'
        # Vertical line
        params = command.parameters
        if command.type == 'v'
          params = makeAbsolute([0, params[0]])
          params = params.slice(1)
        createNode([currentPoint[0], params[0]], i)

      when 'C', 'c', 'Q', 'q'
        # Bezier
        params = command.parameters
        params = makeAbsolute(params) if command.type in ['c', 'q']

        if command.type in ['C', 'c']
          currentPoint = slicePoint(params, 4)
          handleIn = slicePoint(params, 2)
          handleOut = slicePoint(params, 0)
        else
          currentPoint = slicePoint(params, 2)
          handleIn = handleOut = slicePoint(params, 0)

        lastNode = currentSubpath.nodes[currentSubpath.nodes.length - 1]
        lastNode.setAbsoluteHandleOut(handleOut)

        if node = createNode(currentPoint, i)
          node.setAbsoluteHandleIn(handleIn)
        else
          firstNode = currentSubpath.nodes[0]
          firstNode.setAbsoluteHandleIn(handleIn)

      when 'S', 's'
        # Shorthand cubic bezier.
        # Infer last node's handleOut to be a mirror of its handleIn.
        params = command.parameters
        params = makeAbsolute(params) if command.type == 's'

        currentPoint = slicePoint(params, 2)
        handleIn = slicePoint(params, 0)

        lastNode = currentSubpath.nodes[currentSubpath.nodes.length - 1]
        lastNode.join('handleIn')

        if node = createNode(currentPoint, i)
          node.setAbsoluteHandleIn(handleIn)
        else
          firstNode = currentSubpath.nodes[0]
          firstNode.setAbsoluteHandleIn(handleIn)

      when 'T', 't'
        # Shorthand quadradic bezier.
        # Infer node's handles based on previous node's handles
        params = command.parameters
        params = makeAbsolute(params) if command.type == 't'

        currentPoint = slicePoint(params, 0)

        lastNode = currentSubpath.nodes[currentSubpath.nodes.length - 1]
        lastNode.join('handleIn')

        # Use the handle out from the previous node.
        # TODO: Should check if the last node was a Q command...
        # https://developer.mozilla.org/en-US/docs/Web/SVG/Tutorial/Paths#Bezier_Curves
        handleIn = lastNode.getAbsoluteHandleOut()

        if node = createNode(currentPoint, i)
          node.setAbsoluteHandleIn(handleIn)
        else
          firstNode = currentSubpath.nodes[0]
          firstNode.setAbsoluteHandleIn(handleIn)

      when 'Z', 'z'
        currentSubpath.closed = true

  for subpath in result.subpaths
    node.computeIsjoined() for node in subpath.nodes

  result

# Returns a list of svg commands with their parameters.
#   [
#     {type: 'M', parameters: [10, 30]},
#     {type: 'L', parameters: [340, 300]},
#   ]
groupCommands = (pathTokens) ->
  #console.log 'grouping tokens', pathTokens
  commands = []
  for i in [0...pathTokens.length]
    token = pathTokens[i]

    continue unless token.type == COMMAND

    command =
      type: token.string
      parameters: []

    while nextToken = pathTokens[i+1]
      if nextToken.type == NUMBER
        command.parameters.push(parseFloat(nextToken.string))
        i++
      else
        break

    #console.log command.type, command
    commands.push(command)

  commands

# Breaks pathString into tokens
lexPath = (pathString) ->
  numberMatch = '-0123456789.'
  separatorMatch = ' ,\n\t'

  tokens = []
  currentToken = null

  saveCurrentTokenWhenDifferentThan = (command) ->
    saveCurrentToken() if currentToken and currentToken.type != command

  saveCurrentToken = ->
    return unless currentToken
    currentToken.string = currentToken.string.join('') if currentToken.string.join
    tokens.push(currentToken)
    currentToken = null

  for ch in pathString
    if numberMatch.indexOf(ch) > -1
      saveCurrentTokenWhenDifferentThan(NUMBER)
      saveCurrentToken() if ch == '-'

      currentToken = {type: NUMBER, string: []} unless currentToken
      currentToken.string.push(ch)

    else if separatorMatch.indexOf(ch) > -1
      saveCurrentToken()

    else
      saveCurrentToken()
      tokens.push(type: COMMAND, string: ch)

  saveCurrentToken()
  tokens

Curve.PathParser = {lexPath, parsePath, groupCommands, parseTokens}

_ = window._ or require 'underscore'

EventEmitter = window.EventEmitter or require('events').EventEmitter

attrs = {fill: '#eee', stroke: 'none'}

IDS = 0

# Represents a <path> svg element. Contains one or more `Curve.Subpath` objects
class Path extends EventEmitter
  constructor: (@svgDocument, {svgEl}={}) ->
    @id = IDS++
    @subpaths = []
    @_setupSVGObject(svgEl)

  toString: ->
    "Path #{@id} #{@toPathString()}"
  toPathString: ->
    (subpath.toPathString() for subpath in @subpaths).join(' ')

  getNodes: ->
    _.flatten(subpath.getNodes() for subpath in @subpaths, true)

  enableDragging: (callbacks) ->
    element = @svgEl
    return unless element?
    @disableDragging()
    element.draggable()
    element.dragstart = (event) -> callbacks.dragstart?(event)
    element.dragmove = (event) =>
      @update({translate: {x: event.x, y: event.y}})
      callbacks.dragmove?(event)
    element.dragend = (event) =>
      @transform = null
      @translate([event.x, event.y])
      callbacks.dragend?(event)

  disableDragging: ->
    element = @svgEl
    return unless element?
    element.fixed?()
    element.dragstart = null
    element.dragmove = null
    element.dragend = null

  # FIXME: the currentSubpath thing will probably leave. depends on how insert
  # nodes works in interface.
  addNode: (node) ->
    @_addCurrentSubpathIfNotPresent()
    @currentSubpath.addNode(node)
  insertNode: (node, index) ->
    @_addCurrentSubpathIfNotPresent()
    @currentSubpath.insertNode(node, index)
  close: ->
    @_addCurrentSubpathIfNotPresent()
    @currentSubpath.close()
  _addCurrentSubpathIfNotPresent: ->
    @currentSubpath = @_createSubpath() unless @currentSubpath
  # End currentSubpath stuff

  addSubpath: (subpath) ->
    @subpaths.push(subpath)
    @_bindSubpath(subpath)

    args =
      event: 'add:subpath'
      value: subpath
    @emit(args.event, this, args)
    @emit('change', this, args)
    subpath

  translate: (point) ->
    point = Point.create(point)
    for subpath in @subpaths
      subpath.translate(point)
    return

  # Call to update the model based on potentially changed node attributes
  update: (event) ->
    @transform = @svgEl.attr('transform')
    @emit 'change', this, event

  # Will render the nodes and the transform
  render: (svgEl=@svgEl) ->
    pathStr = @toPathString()
    svgEl.attr(d: pathStr) if pathStr
    svgEl.attr(transform: @transform)

  onSubpathEvent: (subpath, eventArgs) =>
    @emit eventArgs.event, this, _.extend({subpath}, eventArgs)

  onSubpathChange: (subpath, eventArgs) =>
    @render()
    @emit 'change', this, _.extend({subpath}, eventArgs)

  _createSubpath: (args) ->
    @addSubpath(new Subpath(_.extend({path: this}, args)))

  _bindSubpath: (subpath) ->
    return unless subpath
    subpath.on 'change', @onSubpathChange
    subpath.on 'close', @onSubpathEvent
    subpath.on 'insert:node', @onSubpathEvent
    subpath.on 'replace:nodes', @onSubpathEvent

  _unbindSubpath: (subpath) ->
    return unless subpath
    subpath.off 'change', @onSubpathChange
    subpath.off 'close', @onSubpathEvent
    subpath.off 'insert:node', @onSubpathEvent
    subpath.off 'replace:nodes', @onSubpathEvent

  _parseFromPathString: (pathString) ->
    return unless pathString

    parsedPath = Curve.PathParser.parsePath(pathString)
    @_createSubpath(parsedSubpath) for parsedSubpath in parsedPath.subpaths

    @currentSubpath = _.last(@subpaths)

    null

  _setupSVGObject: (@svgEl) ->
    @svgEl = @svgDocument.path().attr(attrs) unless @svgEl
    Curve.Utils.setObjectOnNode(@svgEl.node, this)
    @_parseFromPathString(@svgEl.attr('d'))

Curve.Path = Path

#
class Curve.PenTool
  currentObject: null
  currentNode: null

  constructor: (@svgDocument, {@selectionModel, @selectionView}={}) ->

  activate: ->
    @svgDocument.on 'mousedown', @onMouseDown
    @svgDocument.on 'mousemove', @onMouseMove
    @svgDocument.on 'mouseup', @onMouseUp

  deactivate: ->
    @svgDocument.off 'mousedown', @onMouseDown
    @svgDocument.off 'mousemove', @onMouseMove
    @svgDocument.off 'mouseup', @onMouseUp

  onMouseDown: (e) =>
    makeNode = =>
      @currentNode = new Curve.Node([e.clientX, e.clientY], [0, 0], [0, 0])
      @currentObject.addNode(@currentNode)
      @selectionModel.setSelectedNode(@currentNode)

    if @currentObject
      if @selectionView.nodeEditors.length and e.target == @selectionView.nodeEditors[0].nodeElement.node
        @currentObject.close()
        @currentObject = null
      else
        makeNode()
    else
      @currentObject = new Curve.Path(@svgDocument)
      @selectionModel.setSelected(@currentObject)
      makeNode()

  onMouseMove: (e) =>
    @currentNode.setAbsoluteHandleOut([e.clientX, e.clientY]) if @currentNode

  onMouseUp: (e) =>
    @currentNode = null

_ = window._ or require 'underscore'

#
class Point
  @create: (x, y) ->
    return x if x instanceof Point
    if Array.isArray(x)
      new Point(x[0], x[1])
    else
      new Point(x, y)

  constructor: (x, y) ->
    @set(x, y)

  set: (@x, @y) ->
    [@x, @y] = @x if _.isArray(@x)

  add: (other) ->
    other = Point.create(other)
    new Point(@x + other.x, @y + other.y)

  subtract: (other) ->
    other = Point.create(other)
    new Point(@x - other.x, @y - other.y)

  toArray: ->
    [@x, @y]

  equals: (other) ->
    other = Point.create(other)
    other.x == @x and other.y == @y

Curve.Point = Point

$ = window.jQuery or require 'underscore'

class Curve.PointerTool
  constructor: (@svgDocument, {@selectionModel, @selectionView}={}) ->
    @_evrect = @svgDocument.node.createSVGRect();
    @_evrect.width = @_evrect.height = 1;

  activate: ->
    @svgDocument.on 'click', @onClick
    @svgDocument.on 'mousemove', @onMouseMove

    objectSelection = @selectionView.getObjectSelection()
    objectSelection.on 'change:object', @onChangedSelectedObject

  deactivate: ->
    @svgDocument.off 'click', @onClick
    @svgDocument.off 'mousemove', @onMouseMove

    objectSelection = @selectionView.getObjectSelection()
    objectSelection.off 'change:object', @onChangedSelectedObject

  onChangedSelectedObject: ({object, old}) =>
    if object?
      object.enableDragging
        dragstart: (event) ->
          console.log 'start', event
        dragmove: (event) ->
          console.log 'move', event
        dragend: (event) ->
          console.log 'end', event
    else if old?
      old.disableDragging()

  onClick: (e) =>
    # obj = @_hitWithIntersectionList(e)
    obj = @_hitWithTarget(e)
    @selectionModel.setSelected(obj)
    return false if obj

  onMouseMove: (e) =>
    # @selectionModel.setPreselected(@_hitWithIntersectionList(e))
    @selectionModel.setPreselected(@_hitWithTarget(e))

  _hitWithTarget: (e) ->
    obj = null
    obj = Curve.Utils.getObjectFromNode(e.target) if e.target != @svgDocument.node
    obj

  # This seems slower and more complicated than _hitWithTarget
  _hitWithIntersectionList: (e) ->
    {left, top} = $(@svgDocument.node).offset()
    @_evrect.x = e.clientX - left
    @_evrect.y = e.clientY - top
    nodes = @svgDocument.node.getIntersectionList(@_evrect, null)

    obj = null
    if nodes.length
      for i in [nodes.length-1..0]
        clas = nodes[i].getAttribute('class')
        continue if clas and clas.indexOf('invisible-to-hit-test') > -1
        obj = Curve.Utils.getObjectFromNode(nodes[i])
        break

    obj

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

  onInsertNode: (object, {value, index}={}) =>
    @_addNodeEditor(value)
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

_ = window._ or require 'underscore'

EventEmitter = window.EventEmitter or require('events').EventEmitter

# Subpath handles a single path from move node -> close node.
#
# Svg paths can have many subpaths like this:
#
#   M50,50L20,30Z  M4,5L2,3Z
#
# Each one of these will be represented by this Subpath class.
class Subpath extends EventEmitter
  constructor: ({@path, @closed, nodes}={}) ->
    @nodes = []
    @setNodes(nodes)
    @closed = !!@closed

  toString: ->
    "Subpath #{@toPathString()}"

  toPathString: ->
    path = ''
    lastPoint = null

    makeCurve = (fromNode, toNode) ->
      curve = ''
      if fromNode.handleOut or toNode.handleIn
        # use a bezier
        curve = []
        curve = curve.concat(fromNode.getAbsoluteHandleOut().toArray())
        curve = curve.concat(toNode.getAbsoluteHandleIn().toArray())
        curve = curve.concat(toNode.point.toArray())
        curve = "C#{curve.join(',')}"

      else if fromNode.point.x == toNode.point.x
        curve = "V#{toNode.point.y}"

      else if fromNode.point.y == toNode.point.y
        curve = "H#{toNode.point.x}"

      else
        curve = "L#{toNode.point.toArray().join(',')}"

      curve

    closePath = (firstNode, lastNode)->
      return '' unless firstNode and lastNode
      closingPath = ''
      closingPath += makeCurve(lastNode, firstNode) if lastNode.handleOut or firstNode.handleIn
      closingPath += 'Z'

    for node in @nodes
      if path
        path += makeCurve(lastNode, node)
      else
        path += 'M' + node.point.toArray().join(',')

      lastNode = node

    path += closePath(@nodes[0], @nodes[@nodes.length-1]) if @closed
    path

  getNodes: -> @nodes

  setNodes: (nodes) ->
    return unless nodes and _.isArray(nodes)

    @_unbindNode(node) for node in @nodes
    @_bindNode(node) for node in nodes

    @nodes = nodes

    args =
      event: 'replace:nodes'
      value: @nodes
    @emit(args.event, this, args)
    @emit('change', this, args)

  addNode: (node) ->
    @insertNode(node, @nodes.length)

  insertNode: (node, index) ->
    @_bindNode(node)
    @nodes.splice(index, 0, node)

    args =
      event: 'insert:node'
      index: index
      value: node
    @emit('insert:node', this, args)
    @emit('change', this, args)

  close: ->
    @closed = true

    args = event: 'close'
    @emit('close', this, args)
    @emit('change', this, args)

  translate: (point) ->
    point = Point.create(point)
    for node in @nodes
      node.translate(point)
    return

  onNodeChange: (node, eventArgs) =>
    index = @_findNodeIndex(node)
    @emit 'change', this, _.extend({index}, eventArgs)

  _bindNode: (node) ->
    node.on 'change', @onNodeChange
  _unbindNode: (node) ->
    node.off 'change', @onNodeChange

  _findNodeIndex: (node) ->
    for i in [0...@nodes.length]
      return i if @nodes[i] == node
    -1

Curve.Subpath = Subpath

SVG = window.SVG or require('./vendor/svg').SVG

class SvgDocument
  constructor: (rootNode) ->
    @objects = []
    @svgDocument = SVG(rootNode)

    @toolLayer = @svgDocument.group()
    @toolLayer.node.setAttribute('class', 'tool-layer')

    @selectionModel = new Curve.SelectionModel()
    @selectionView = new Curve.SelectionView(@toolLayer, @selectionModel)

    @tool = new Curve.PointerTool(@svgDocument, {@selectionModel, @selectionView})
    @tool.activate()

  deserialize: (svgString) ->
    # See `ext/svg.import.coffee` for import implementation
    @objects = Curve.import(@svgDocument, svgString)
    @toolLayer.front()

  serialize: ->
    svgRoot = @getSvgRoot()
    if svgRoot
      svgRoot.export(whitespace: true)
    else
      ''

  getSvgRoot: ->
    svgRoot = null
    @svgDocument.each -> svgRoot = this if this.node.nodeName == 'svg'
    svgRoot

Curve.SvgDocument = SvgDocument

class SVGObject extends Mixin
  enableDraggingOnObject: (object, callbacks) ->
    element = object.svgEl
    return unless element?
    @disableDragging()
    element.draggable()
    element.dragstart = (event) -> callbacks.dragstart?(event)
    element.dragmove = (event) ->
      object.didChange({translate: {x: event.x, y: event.y}})
      callbacks.dragmove?(event)
    element.dragend = (event) -> callbacks.dragend?(event)

  disableDraggingOnObject: (object) ->
    element = object.svgEl
    return unless element?
    element.fixed?()
    element.dragstart = null
    element.dragmove = null
    element.dragend = null

_ = window._ or require 'underscore'
$ = window.jQuery or require 'jquery'

Curve.Utils =
  getObjectFromNode: (domNode) ->
    $.data(domNode, 'curve.object')
  setObjectOnNode: (domNode, object) ->
    $.data(domNode, 'curve.object', object)
  pointForEvent: (svgDocument, event) ->
    {clientX, clientY} = event
    {top, left} = $(svgDocument.node).offset()
    new Curve.Point(event.clientX - left, event.clientY - top)
