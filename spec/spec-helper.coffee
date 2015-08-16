require '../vendor/svg'
require '../src/ext/svg-circle'
require '../src/ext/svg-draggable'
require "../vendor/svg.parser"
require "../vendor/svg.export"

util = require 'util'
ObjectAssign = require 'object-assign'

jasmine.buildMouseEvent = (type, properties...) ->
  properties = ObjectAssign({bubbles: true, cancelable: true}, properties...)
  properties.detail ?= 1
  event = new MouseEvent(type, properties)
  Object.defineProperty(event, 'which', get: -> properties.which) if properties.which?
  if properties.target?
    Object.defineProperty(event, 'target', get: -> properties.target)
    Object.defineProperty(event, 'srcObject', get: -> properties.target)
  if properties.pageX?
    Object.defineProperty(event, 'pageX', get: -> properties.pageX)
  if properties.pageY?
    Object.defineProperty(event, 'pageY', get: -> properties.pageY)
  if properties.offsetX?
    Object.defineProperty(event, 'offsetX', get: -> properties.offsetX)
  if properties.offsetY?
    Object.defineProperty(event, 'offsetY', get: -> properties.offsetY)
  event

jasmine.buildMouseParams = (x, y) ->
  pageX: x
  pageY: y
  offsetX: x
  offsetY: y

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
