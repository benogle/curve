require '../vendor/svg'
require '../src/ext/svg-circle'
require '../src/ext/svg-draggable'
require "../vendor/svg.parser"
require "../vendor/svg.export"

util = require 'util'

beforeEach ->
  jasmine.addMatchers
    toShow: ->
      compare: (actual) ->
        pass = getComputedStyle(actual)['display'] isnt 'none'
        {pass}

    toHide: ->
      compare: (actual) ->
        pass = getComputedStyle(actual)['display'] is 'none'
        {pass}

    toHaveLength: ->
      compare: (actual, expectedValue) ->
        actualValue = actual.length
        pass = actualValue is expectedValue
        notStr = if pass then ' not' else ''
        message = "Expected array with length #{actualValue} to#{notStr} have length #{expectedValue}"
        {pass, message}

    toHaveAttr: ->
      compare: (actual, attr, expectedValue) ->
        actualValue = actual.getAttribute(attr)
        pass = actualValue is expectedValue
        notStr = if pass then ' not' else ''
        message = "Expected attr '#{attr}' to#{notStr} be #{JSON.stringify(expectedValue)} but it was #{JSON.stringify(actualValue)}"
        {pass, message}
