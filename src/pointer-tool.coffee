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
