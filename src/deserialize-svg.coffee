SVG = require "../vendor/svg"
require "../vendor/svg.parser"

Path = require "./path"
Rectangle = require "./rectangle"

# svg.import.js 0.11 - Copyright (c) 2013 Wout Fierens - Licensed under the MIT license
#
# Converted to coffeescript and modified by benogle

# Place the `svgString` in the svgDocument, and parse into objects Curve can
# understand
#
# * `svgDocument` A {SVGDocument}
# * `svgString` {String} with the svg markup
#
# Returns an array of objects selectable and editable by Curve tools.
module.exports = (svgDocument, svgString) ->
  IMPORT_FNS =
    path: (el) -> [new Path(svgDocument, svgEl: el)]
    rect: (el) -> [new Rectangle(svgDocument, svgEl: el)]

  # create temporary div to receive svg content
  parentNode = document.createElement('div')
  store = {}

  # properly close svg tags and add them to the DOM
  parentNode.innerHTML = svgString
    .replace(/\n/, '')
    .replace(/<(\w+)([^<]+?)\/>/g, '<$1$2></$1>')

  objects = []
  convertNodes parentNode.childNodes, svgDocument.getSVGRoot(), 0, store, ->
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
    attr = SVG.parse.attr(child)

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
                  .attr(SVG.parse.attr(grandchild))

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
              .at(offset: 0)
              .attr(SVG.parse.attr(child.childNodes[j]))
              .style(child.childNodes[j].getAttribute('style'))

      when '#comment', '#text', 'metadata', 'desc'
        ; # safely ignore these elements
      else
        console.log('SVG Import got unexpected type ' + type, child)

    if element
      # parse transform attribute
      transform = SVG.parse.transform(attr.transform)
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
