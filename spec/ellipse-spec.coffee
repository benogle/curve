SVGDocument = require '../src/svg-document'

Ellipse = require '../src/ellipse'
Point = require '../src/point'
Size = require '../src/size'

describe 'Ellipse', ->
  [svg, ellipse] = []

  beforeEach ->
    canvas = document.createElement('canvas')
    jasmine.attachToDOM(canvas)
    svg = new SVGDocument(canvas)

  describe "creation", ->
    it 'has an id', ->
      ellipse = new Ellipse(svg)
      expect(ellipse.getID()).toBe "Ellipse-#{ellipse.model.id}"

    it 'registers itself with the document', ->
      ellipse = new Ellipse(svg)
      expect(svg.getObjects()).toContain ellipse

    it 'emits an event when it is removed', ->
      ellipse = new Ellipse(svg)
      ellipse.on 'remove', removeSpy = jasmine.createSpy()
      ellipse.remove()
      expect(removeSpy).toHaveBeenCalledWith({object: ellipse})

    it 'can be created with no parameters', ->
      ellipse = new Ellipse(svg)

      el = ellipse.svgEl
      expect(el.attr('cx')).toBe 5
      expect(el.attr('cy')).toBe 5
      expect(el.attr('rx')).toBe 5
      expect(el.attr('ry')).toBe 5

    it 'can be created with parameters', ->
      ellipse = new Ellipse(svg, {x: 10, y: 20, width: 200, height: 300, fill: '#ff0000'})

      el = ellipse.svgEl
      expect(el.attr('cx')).toBe 110
      expect(el.attr('cy')).toBe 170
      expect(el.attr('rx')).toBe 100
      expect(el.attr('ry')).toBe 150
      expect(el.attr('fill')).toBe '#ff0000'

      expect(ellipse.get('position')).toEqual Point.create(10, 20)
      expect(ellipse.get('size')).toEqual Size.create(200, 300)

    describe "updating attributes", ->
      beforeEach ->
        ellipse = new Ellipse(svg, {x: 10, y: 20, width: 200, height: 300, fill: '#ff0000'})

      it "emits an event with the object, model, old, and new values when changed", ->
        ellipse.on('change', changeSpy = jasmine.createSpy())
        ellipse.set(fill: '#00ff00')

        arg = changeSpy.calls.mostRecent().args[0]
        expect(changeSpy).toHaveBeenCalled()
        expect(arg.object).toBe ellipse
        expect(arg.model).toBe ellipse.model
        expect(arg.value).toEqual fill: '#00ff00'
        expect(arg.oldValue).toEqual fill: '#ff0000'

      it "can have its fill color changed", ->
        el = ellipse.svgEl
        expect(el.attr('fill')).toBe '#ff0000'

        ellipse.set(fill: '#00ff00')
        expect(el.attr('fill')).toBe '#00ff00'
        expect(ellipse.get('fill')).toBe '#00ff00'
