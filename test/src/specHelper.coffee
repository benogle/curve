jasmine.getFixtures().fixturesPath = 'test/fixtures'
jasmine.getStyleFixtures().fixturesPath = 'test/fixtures'

beforeEach ->
  @addMatchers
    toShow: (exp) ->
      actual = this.actual
      actual.css('display') != 'none'

    toHide: (exp) ->
      actual = this.actual
      actual.css('display') == 'none'

if !Function::bind
  Function::bind = (oThis) ->
    if typeof this != 'function'
      # closest thing possible to the ECMAScript 5
      # internal IsCallable function
      throw new TypeError('Function.prototype.bind - what is trying to be bound is not callable')
    aArgs = Array::slice.call(arguments, 1)
    fToBind = this

    fNOP = ->
    fBound = ->
      context = if this instanceof fNOP then this else oThis
      fToBind.apply(context,aArgs.concat(Array.prototype.slice.call(arguments)))
    fNOP.prototype = @prototype
    fBound.prototype = new fNOP
    fBound
