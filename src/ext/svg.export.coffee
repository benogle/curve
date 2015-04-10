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
