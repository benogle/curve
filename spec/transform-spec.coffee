Point = require '../src/point'
Transform = require '../src/transform'

describe 'Curve.Transform', ->
  [trans, point] = []
  beforeEach ->
    point = new Point(20, 30)
    trans = new Transform()

  describe "when there is not a translation", ->
    it 'does not transform the point', ->
      expect(trans.transformPoint(point)).toBe point

  describe "when the transform has a translation", ->
    beforeEach ->
      expect(trans.setTransformString('translate(-5 6)')).toBe true

    it 'translates the point', ->
      expect(trans.transformPoint(point)).toEqual new Point(15, 36)
      expect(trans.setTransformString(null)).toBe true
      expect(trans.transformPoint(point)).toEqual point
      expect(trans.setTransformString(null)).toBe false
