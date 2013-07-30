[COMMAND, NUMBER] = ['COMMAND', 'NUMBER']

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

  tokens

# Parses the result of lexPath
parsePath = (pathTokens) ->

_.extend(window.Curve, {lexPath, parsePath})
