Curve = {}

if typeof module != 'undefined'
  module.exports = Curve
else
  window.Curve = Curve

SVG = window.SVG or require('./vendor/svg').SVG

# svg.export.js 0.8 - Copyright (c) 2013 Wout Fierens - Licensed under the MIT license
#
# Coffeescript'd and modified by benogle
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

Curve.import = (svgDocument, svgString) ->
  IMPORT_FNS =
    path: (el) -> [new Curve.Path(svgDocument, svgEl: el)]

  # create temporary div to receive svg content
  well = document.createElement('div')
  store = {}

  # properly close svg tags and add them to the DOM
  well.innerHTML = svgString
    .replace(/\n/, '')
    .replace(/<(\w+)([^<]+?)\/>/g, '<$1$2></$1>')

  objects = []
  convertNodes well.childNodes, svgDocument, 0, store, ->
    nodeType = this.node.nodeName
    objects = objects.concat(IMPORT_FNS[nodeType](this)) if IMPORT_FNS[nodeType]
    null

  well = null
  objects

_ = window._ or require 'underscore'
$ = window.jQuery or require 'jquery'

#
class NodeEditor
  nodeSize: 5
  handleSize: 3

  node = null
  nodeElement = null
  handleElements = null
  lineElement = null

  constructor: (@svgDocument, @selectionModel) ->
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
    @nodeElement = @svgDocument.circle(@nodeSize)
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
    @lineElement = @svgDocument.path('')
    @lineElement.node.setAttribute('class', 'node-editor-lines')

  _setupHandleElements: ->
    self = this

    @handleElements = @svgDocument.set()
    @handleElements.add(
      @svgDocument.circle(@handleSize),
      @svgDocument.circle(@handleSize)
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
    point = Point.create(point)
    @set('handleIn', point)
    @set('handleOut', new Curve.Point(0,0).subtract(point)) if @isJoined
  setHandleOut: (point) ->
    point = Point.create(point)
    @set('handleOut', point)
    @set('handleIn', new Curve.Point(0,0).subtract(point)) if @isJoined

  computeIsjoined: ->
    @isJoined = (not @handleIn and not @handleOut) or (@handleIn and @handleOut and Math.round(@handleIn.x) == Math.round(-@handleOut.x) and Math.round(@handleIn.y) == Math.round(-@handleOut.y))

  set: (attribute, value) ->
    old = @[attribute]
    @[attribute] = value

    event = "change:#{attribute}"
    eventArgs = {event, value, old}

    @emit event, this, eventArgs
    @emit 'change', this, eventArgs

Curve.Node = Node


#
class Curve.ObjectSelection
  constructor: (@svgDocument, @options={}) ->
    @options.class ?= 'object-selection'

  setObject: (object) ->
    @_unbindObject(@object)
    @object = object
    @_bindObject(@object)

    @path.remove() if @path
    @path = null
    if @object
      @path = @svgDocument.path('').back()
      @path.node.setAttribute('class', @options.class + ' invisible-to-hit-test')
      @render()

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
  result =
    subpaths: []

  # Just a move command? We dont care.
  return result if groupedCommands.length == 1 and groupedCommands[0].type in ['M', 'm']

  currentPoint = null # svg is stateful. Each command will set this.
  firstHandle = null

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

  makeAbsolute = (array) ->
    _.map array, (val, i) ->
      val + currentPoint[i % 2]

  for i in [0...groupedCommands.length]
    command = groupedCommands[i]
    switch command.type
      when 'M'
        currentPoint = command.parameters
        addNewSubpath(currentPoint)

      when 'L', 'l'
        params = command.parameters
        params = makeAbsolute(params) if command.type == 'l'

        currentPoint = slicePoint(params, 0)
        currentSubpath.nodes.push(new Node(currentPoint))

      when 'H', 'h'
        params = command.parameters
        params = makeAbsolute(params) if command.type == 'h'

        currentPoint = [params[0], currentPoint[1]]
        currentSubpath.nodes.push(new Node(currentPoint))

      when 'V', 'v'
        params = command.parameters
        if command.type == 'v'
          params = makeAbsolute([0, params[0]])
          params = params.slice(1)

        currentPoint = [currentPoint[0], params[0]]
        currentSubpath.nodes.push(new Node(currentPoint))

      when 'C', 'c'
        params = command.parameters
        params = makeAbsolute(params) if command.type == 'c'

        currentPoint = slicePoint(params, 4)
        handleIn = slicePoint(params, 2)
        handleOut = slicePoint(params, 0)

        firstNode = currentSubpath.nodes[0]
        lastNode = currentSubpath.nodes[currentSubpath.nodes.length - 1]
        lastNode.setAbsoluteHandleOut(handleOut)

        nextCommand = groupedCommands[i + 1]
        if nextCommand and nextCommand.type in ['z', 'Z'] and firstNode and firstNode.point.equals(currentPoint)
          firstNode.setAbsoluteHandleIn(handleIn)
        else
          curveNode = new Node(currentPoint)
          curveNode.setAbsoluteHandleIn(handleIn)
          currentSubpath.nodes.push(curveNode)

      when 'Z', 'z'
        currentSubpath.closed = true

  for subpath in result.subpaths
    node.computeIsjoined() for node in subpath.nodes

  result

# Returns a list of svg commands with their parameters.
groupCommands = (pathTokens) ->
  console.log 'grouping tokens', pathTokens
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

    console.log command.type, command
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
#
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

  render: (svgEl=@svgEl) ->
    pathStr = @toPathString()
    svgEl.attr(d: pathStr) if pathStr

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

  deactivate: ->
    @svgDocument.off 'click', @onClick
    @svgDocument.off 'mousemove', @onMouseMove

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

#
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
      curve = []
      curve = curve.concat(fromNode.getAbsoluteHandleOut().toArray())
      curve = curve.concat(toNode.getAbsoluteHandleIn().toArray())
      curve = curve.concat(toNode.point.toArray())
      'C' + curve.join(',')

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
    @objects = Curve.import(@svgDocument, svgString)
    @toolLayer.front()

  serialize: ->
    svgRoot = null
    @svgDocument.each -> svgRoot = this if this.node.nodeName == 'svg'

    if svgRoot
      svgRoot.export(whitespace: true)
    else
      ''

Curve.SvgDocument = SvgDocument

_ = window._ or require 'underscore'
$ = window.jQuery or require 'jquery'

Curve.Utils =
  getObjectFromNode: (domNode) ->
    $.data(domNode, 'curve.object')
  setObjectOnNode: (domNode, object) ->
    $.data(domNode, 'curve.object', object)
