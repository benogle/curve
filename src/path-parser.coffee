_ = require 'underscore'

require './node'

[COMMAND, NUMBER] = ['COMMAND', 'NUMBER']

parsePath = (pathString) ->
  #console.log 'parsing', pathString
  tokens = lexPath(pathString)
  parseTokens(groupCommands(tokens))

# Parses the result of lexPath
parseTokens = (groupedCommands) ->
  result =
    closed: false
    nodes: []

  currentPoint = null # svg is stateful. Each command will set this.
  firstHandle = null

  movePoint = null
  makeMoveNode = ->
    return unless movePoint
    node = new Curve.Node(movePoint)
    node.isMoveNode = true
    movePoint = null
    result.nodes.push(node)
    node

  slicePoint = (array, index) ->
    [array[index], array[index + 1]]

  makeAbsolute = (array) ->
    _.map array, (val, i) ->
      val + currentPoint[i % 2]

  for i in [0...groupedCommands.length]
    command = groupedCommands[i]
    switch command.type
      when 'M'
        movePoint = currentPoint = command.parameters

      when 'L', 'l'
        moveNode = makeMoveNode()
        firstNode = moveNode if moveNode

        params = command.parameters
        params = makeAbsolute(params) if command.type == 'l'

        currentPoint = slicePoint(params, 0)
        result.nodes.push(new Curve.Node(currentPoint))

      when 'H', 'h'
        moveNode = makeMoveNode()
        firstNode = moveNode if moveNode

        params = command.parameters
        params = makeAbsolute(params) if command.type == 'h'

        currentPoint = [params[0], currentPoint[1]]
        result.nodes.push(new Curve.Node(currentPoint))

      when 'V', 'v'
        moveNode = makeMoveNode()
        firstNode = moveNode if moveNode

        params = command.parameters
        params = makeAbsolute(params) if command.type == 'v'

        currentPoint = [currentPoint[0], params[0]]
        result.nodes.push(new Curve.Node(currentPoint))

      when 'C', 'c'
        moveNode = makeMoveNode()
        firstNode = moveNode if moveNode

        params = command.parameters
        params = makeAbsolute(params) if command.type == 'c'

        currentPoint = slicePoint(params, 4)
        handleIn = slicePoint(params, 2)
        handleOut = slicePoint(params, 0)

        lastNode = result.nodes[result.nodes.length - 1]
        lastNode.setAbsoluteHandleOut(handleOut)

        nextCommand = groupedCommands[i + 1]

        if nextCommand and nextCommand.type in ['z', 'Z'] and firstNode and firstNode.point.equals(currentPoint)
          firstNode.setAbsoluteHandleIn(handleIn)
        else
          curveNode = new Curve.Node(currentPoint)
          curveNode.setAbsoluteHandleIn(handleIn)
          result.nodes.push(curveNode)

      when 'Z', 'z'
        lastNode = result.nodes[result.nodes.length - 1]
        lastNode.isCloseNode = true if lastNode
        result.closed = true

  node.computeIsjoined() for node in result.nodes
  result

# Returns a list of svg commands with their parameters.
groupCommands = (pathTokens) ->
  console.log 'grouping tokens', pathTokens
  commands = []
  for i in [0...pathTokens.length]
    token = pathTokens[i]

    continue unless token.type == COMMAND

    command =
      type: token.string
      parameters: []

    while nextToken = pathTokens[i+1]
      if nextToken.type == NUMBER
        command.parameters.push(parseFloat(nextToken.string))
        i++
      else
        break

    console.log command.type, command
    commands.push(command)

  commands

# Breaks pathString into tokens
lexPath = (pathString) ->
  numberMatch = '-0123456789.'
  separatorMatch = ' ,\n\t'

  tokens = []
  currentToken = null

  saveCurrentTokenWhenDifferentThan = (command) ->
    saveCurrentToken() if currentToken and currentToken.type != command

  saveCurrentToken = ->
    return unless currentToken
    currentToken.string = currentToken.string.join('') if currentToken.string.join
    tokens.push(currentToken)
    currentToken = null

  for ch in pathString
    if numberMatch.indexOf(ch) > -1
      saveCurrentTokenWhenDifferentThan(NUMBER)
      saveCurrentToken() if ch == '-'

      currentToken = {type: NUMBER, string: []} unless currentToken
      currentToken.string.push(ch)

    else if separatorMatch.indexOf(ch) > -1
      saveCurrentToken()

    else
      saveCurrentToken()
      tokens.push(type: COMMAND, string: ch)

  saveCurrentToken()
  tokens

_.extend(window.Curve, {lexPath, parsePath, groupCommands, parseTokens})
