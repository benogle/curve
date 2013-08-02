###
  TODO
  * experiment with loading a file then editing it
  * change path -> svgEl in cases where it makes sense
  * removing nodes with keyboard
  * move entire object
  * select/deselect objects
  * make new objects
  * replacing path array updates the interface

  Large
  * how to deal with events and tools and things?
    * like NodeEditor is dragging something, the pointer tool should be deactivated.
    * a tool manager? can push/pop tools?
  * probably need a doc object
    * Can pass it to everything that needs to use svg
    * would have access to the tools n junk
  * proper z-index of elements
    * group for doc at the bottom
    * group for selection
    * group for tool nodes
###

window.main = ->
  svg = SVG("canvas")
  Curve.import(svg, Curve.Examples.heckert)

  @selectionModel = new Curve.SelectionModel()
  @selectionView = new Curve.SelectionView(svg, @selectionModel)

  @tool = new Curve.PointerTool(svg, {@selectionModel, @selectionView})
  @tool.activate()

window._main = ->
  svg = SVG("canvas")

  @path1 = new Path(svg)
  @path1.addNode(new Node([50, 50], [-10, 0], [10, 0]))
  @path1.addNode(new Node([80, 60], [-10, -5], [10, 5]))
  @path1.addNode(new Node([60, 80], [10, 0], [-10, 0]))
  @path1.close()

  @path2 = new Path(svg)
  @path2.addNode(new Node([150, 50], [-10, 0], [10, 0]))
  @path2.addNode(new Node([220, 100], [-10, -5], [10, 5]))
  @path2.addNode(new Node([160, 120], [10, 0], [-10, 0]))
  @path2.close()

  @path2.svgEl.attr
    fill: 'none'
    stroke: '#333'
    'stroke-width': 2

  @selectionModel = new Curve.SelectionModel()
  @selectionView = new Curve.SelectionView(svg, selectionModel)

  @selectionModel.setSelected(@path1)
  @selectionModel.setSelectedNode(@path1.nodes[2])

  @tool = new Curve.PointerTool(svg, {selectionModel, selectionView})
  @tool.activate()

  @pen = new Curve.PenTool(svg, {selectionModel, selectionView})
  #@pen.activate()
