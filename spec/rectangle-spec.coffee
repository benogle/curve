SVGDocument = require '../src/svg-document'

Rectangle = require '../src/rectangle'
Point = require '../src/point'
Size = require '../src/size'

describe 'Rectangle', ->
  [svg, rect] = []

  beforeEach ->
    canvas = document.createElement('canvas')
    jasmine.attachToDOM(canvas)
    svg = new SVGDocument(canvas)

  describe "creation", ->
    it 'has an id', ->
      rect = new Rectangle(svg)
      expect(rect.getID()).toBe "Rectangle-#{rect.id}"

    it 'registers itself with the document', ->
      rect = new Rectangle(svg)
      expect(svg.getObjects()).toContain rect

    it 'emits an event when it is removed', ->
      rect = new Rectangle(svg)
      rect.on 'remove', removeSpy = jasmine.createSpy()
      rect.remove()
      expect(removeSpy).toHaveBeenCalledWith({object: rect})

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

      expect(rect.get('position')).toEqual Point.create(10, 20)
      expect(rect.get('size')).toEqual Size.create(200, 300)

    describe "updating attributes", ->
      beforeEach ->
        rect = new Rectangle(svg, {x: 10, y: 20, width: 200, height: 300, fill: '#ff0000'})

      it "emits an event with the object, model, old, and new values when changed", ->
        rect.on('change', changeSpy = jasmine.createSpy())
        rect.set(fill: '#00ff00')

        arg = changeSpy.calls.mostRecent().args[0]
        expect(changeSpy).toHaveBeenCalled()
        expect(arg.object).toBe rect
        expect(arg.model).toBe rect.model
        expect(arg.value).toEqual fill: '#00ff00'
        expect(arg.oldValue).toEqual fill: '#ff0000'

      it "can have its fill color changed", ->
        el = rect.svgEl
        expect(el.attr('fill')).toBe '#ff0000'

        rect.set(fill: '#00ff00')
        expect(el.attr('fill')).toBe '#00ff00'
        expect(rect.get('fill')).toBe '#00ff00'
