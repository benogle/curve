_ = window._ or require 'underscore'

[COMMAND, NUMBER] = ['COMMAND', 'NUMBER']

parsePath = (pathString) ->
  #console.log 'parsing', pathString
  tokens = lexPath(pathString)
  parseTokens(groupCommands(tokens))

# Parses the result of lexPath
parseTokens = (groupedCommands) ->
  result =
    subpaths: []

  # Just a move command? We dont care.
  return result if groupedCommands.length == 1 and groupedCommands[0].type in ['M', 'm']

  currentPoint = null # svg is stateful. Each command will set this.
  firstHandle = null

  currentSubpath = null
  addNewSubpath = (movePoint) ->
    node = new Node(movePoint)
    currentSubpath =
      closed: false
      nodes: [node]
    result.subpaths.push(currentSubpath)
    node

  slicePoint = (array, index) ->
    [array[index], array[index + 1]]

  makeAbsolute = (array) ->
    _.map array, (val, i) ->
      val + currentPoint[i % 2]

  createNode = (point, commandIndex) ->
    currentPoint = point

    node = null
    firstNode = currentSubpath.nodes[0]

    nextCommand = groupedCommands[commandIndex + 1]
    unless nextCommand and nextCommand.type in ['z', 'Z'] and firstNode and firstNode.point.equals(currentPoint)
      node = new Node(currentPoint)
      currentSubpath.nodes.push(node)

    node

  for i in [0...groupedCommands.length]
    command = groupedCommands[i]
    switch command.type
      when 'M'
        currentPoint = command.parameters
        addNewSubpath(currentPoint)

      when 'L', 'l'
        params = command.parameters
        params = makeAbsolute(params) if command.type == 'l'
        createNode(slicePoint(params, 0), i)

      when 'H', 'h'
        params = command.parameters
        params = makeAbsolute(params) if command.type == 'h'
        createNode([params[0], currentPoint[1]], i)

      when 'V', 'v'
        params = command.parameters
        if command.type == 'v'
          params = makeAbsolute([0, params[0]])
          params = params.slice(1)
        createNode([currentPoint[0], params[0]], i)

      when 'C', 'c'
        params = command.parameters
        params = makeAbsolute(params) if command.type == 'c'

        currentPoint = slicePoint(params, 4)
        handleIn = slicePoint(params, 2)
        handleOut = slicePoint(params, 0)

        lastNode = currentSubpath.nodes[currentSubpath.nodes.length - 1]
        lastNode.setAbsoluteHandleOut(handleOut)

        if node = createNode(currentPoint, i)
          node.setAbsoluteHandleIn(handleIn)
        else
          firstNode = currentSubpath.nodes[0]
          firstNode.setAbsoluteHandleIn(handleIn)

      when 'S', 's'
        # Shorthand path. Force the last node's handleOut to be a mirror of its handleIn.
        params = command.parameters
        params = makeAbsolute(params) if command.type == 's'

        currentPoint = slicePoint(params, 2)
        handleIn = slicePoint(params, 0)

        lastNode = currentSubpath.nodes[currentSubpath.nodes.length - 1]
        lastNode.join('handleIn')

        if node = createNode(currentPoint, i)
          node.setAbsoluteHandleIn(handleIn)
        else
          firstNode = currentSubpath.nodes[0]
          firstNode.setAbsoluteHandleIn(handleIn)

      when 'Z', 'z'
        currentSubpath.closed = true

  for subpath in result.subpaths
    node.computeIsjoined() for node in subpath.nodes

  result

# Returns a list of svg commands with their parameters.
groupCommands = (pathTokens) ->
  #console.log 'grouping tokens', pathTokens
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

    #console.log command.type, command
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

Curve.PathParser = {lexPath, parsePath, groupCommands, parseTokens}
