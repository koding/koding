globals = require 'globals'

module.exports = providersParser = (content) ->

  regex     = /\$\{var\.(\w+?)\_/g
  providers = {}
  match     = regex.exec content

  while match
    providers[match[1]] = null
    match = regex.exec content

  knownProviders = globals.config.providers
  providers = (Object.keys providers).map (provider) ->
    (Object.keys knownProviders).forEach (_provider) ->
      if knownProviders[_provider].slug is provider
        provider = _provider
    provider

  # Return list of providers
  return providers
