describe 'Curve.Node', ->
  beforeEach ->
    @s = new Curve.Node([50, 50], [-10, 0], [10, 0], true)

  describe 'joined handles', ->
    it 'updating one handle updates the other', ->
      @s.setHandleIn([20, 30])
      expect(@s.handleOut).toEqual new Curve.Point(-20, -30)

      @s.setHandleOut([15, -5])
      expect(@s.handleIn).toEqual new Curve.Point(-15, 5)

    it 'join() will set the other non-joined handle', ->
      @s.isJoined = false
      @s.setHandleIn([0, 0])

      @s.join('handleOut')
      expect(@s.handleIn).toEqual new Curve.Point(-10, 0)

    it 'setting handle to null, mirrors', ->
      @s.setHandleIn(null)
      expect(@s.handleOut).toEqual null
