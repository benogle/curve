[COMMAND, NUMBER] = ['COMMAND', 'NUMBER']

parsePath = (pathString) ->
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
        result.closed = true

  node.computeIsjoined() for node in result.nodes
  result

# Returns a list of svg commands with their parameters.
groupCommands = (pathTokens) ->
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

    commands.push(command)

  commands

# Breaks pathString into tokens
lexPath = (pathString) ->
  numberMatch = '0123456789.'
  separatorMatch = ' ,'

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

      currentToken = {type: NUMBER, string: []} unless currentToken
      currentToken.string.push(ch)

    else if separatorMatch.indexOf(ch) > -1
      saveCurrentToken()

    else
      saveCurrentToken()
      tokens.push(type: COMMAND, string: ch)

  saveCurrentToken()
  tokens

_.extend(window.Curve, {lexPath, parsePath, groupCommands})
