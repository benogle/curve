
# The display for a selected object. i.e. the red or blue outline around the
# selected object.
#
# It basically cops the underlying object's attributes (path definition, etc.)
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
