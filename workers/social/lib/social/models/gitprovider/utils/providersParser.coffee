# TODO: Add support for provider slug support ~ GG
module.exports = providersParser = (content) ->

  regex     = /\$\{var\.(\w+?)\_/g
  providers = {}
  match     = regex.exec content

  while match
    providers[match[1]] = null
    match = regex.exec content

  # Return list of providers
  return Object.keys providers
