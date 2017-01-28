module.exports = isExternal = (mod) ->

  { userRequest } = mod

  return no  if 'string' isnt typeof userRequest

  return userRequest.indexOf('node_modules') >= 0
