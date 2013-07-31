describe 'Curve.Node', ->
  beforeEach ->
    @s = new Curve.Node([50, 50], [-10, 0], [10, 0], true)

  describe 'joined handles', ->
    it 'updating one handle updates the other', ->
      @s.setHandleIn([20, 30])
      expect(@s.handleOut).toEqual new Curve.Point(-20, -30)

      @s.setHandleOut([15, -5])
      expect(@s.handleIn).toEqual new Curve.Point(-15, 5)
