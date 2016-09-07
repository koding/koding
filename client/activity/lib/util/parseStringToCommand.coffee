module.exports = parseStringToCommand = (value) ->

  matchResult = value.match /^(\/[^\s]+)(\s.*)?/
  return  unless matchResult

  name     = matchResult[1]
  paramStr = matchResult[2]
  if paramStr
    params = paramStr.trim().split ' '
    params = (param for param in params when param isnt '')

  return { name, params }
