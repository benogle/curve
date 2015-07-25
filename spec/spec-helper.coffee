require '../src/ext/svg-circle'
require '../src/ext/svg-draggable'
require '../src/ext/svg-export'

beforeEach ->
  jasmine.addMatchers
    toShow: ->
      compare: (actual) ->
        {passed: actual.css('display') != 'none'}

    toHide: ->
      compare: (actual) ->
        {passed: actual.css('display') != 'none'}
