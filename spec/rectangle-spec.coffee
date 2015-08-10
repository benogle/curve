SVGDocument = require '../src/svg-document'

Rectangle = require '../src/rectangle'
Point = require '../src/point'

describe 'Rectangle', ->
  [svg, rect] = []

  beforeEach ->
    canvas = document.createElement('canvas')
    jasmine.attachToDOM(canvas)
    svg = new SVGDocument(canvas)

  describe "creation", ->
    it 'registers itself with the document', ->
      rect = new Rectangle(svg)
      expect(svg.getObjects()).toContain rect

    it 'can be created with no parameters', ->
      rect = new Rectangle(svg)

      el = rect.svgEl
      expect(el.attr('x')).toBe 0
      expect(el.attr('y')).toBe 0
      expect(el.attr('width')).toBe 10
      expect(el.attr('height')).toBe 10

    it 'can be created with parameters', ->
      rect = new Rectangle(svg, {x: 10, y: 20, width: 200, height: 300, fill: '#ff0000'})

      el = rect.svgEl
      expect(el.attr('x')).toBe 10
      expect(el.attr('y')).toBe 20
      expect(el.attr('width')).toBe 200
      expect(el.attr('height')).toBe 300
      expect(el.attr('fill')).toBe '#ff0000'
