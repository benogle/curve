utils = window.Curve

class PointerTool
  constructor: (svg, {@selectionModel, @selectionView}={}) ->
    @_evrect = svg.node.createSVGRect();
    @_evrect.width = @_evrect.height = 1;

  activate: ->
    svg.on 'click', @onClick
    svg.on 'mousemove', @onMouseMove

  deactivate: ->
    svg.off 'click', @onClick
    svg.off 'mousemove', @onMouseMove

  onClick: (e) =>
    obj = @_hitWithIntersectionList(e)
    @selectionModel.setSelected(obj)
    return false if obj

  onMouseMove: (e) =>
    @selectionModel.setPreselected(@_hitWithIntersectionList(e))
    # @selectionModel.setPreselected(@_hitWithTarget(e))

  _hitWithTarget: (e) ->
    obj = null
    obj = utils.getObjectFromNode(e.target) if e.target != svg.node
    obj

  _hitWithIntersectionList: (e) ->
    @_evrect.x = e.clientX
    @_evrect.y = e.clientY
    nodes = svg.node.getIntersectionList(@_evrect, null)

    obj = null
    if nodes.length
      for i in [nodes.length-1..0]
        clas = nodes[i].getAttribute('class')
        continue if clas and clas.indexOf('invisible-to-hit-test') > -1
        obj = utils.getObjectFromNode(nodes[i])
        break

    obj
