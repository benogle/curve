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
