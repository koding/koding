globals = require 'globals'

module.exports = providersParser = (content) ->

  regex     = /\$\{var\.(\w+?)\_/g
  providers = {}
  match     = regex.exec content

  while match
    providers[match[1]] = null
    match = regex.exec content

  supportedProviders = globals.config.providers._getSupportedProviders()
  providers = (Object.keys providers)
    .filter (provider) ->
      provider is 'userInput' or
      provider in supportedProviders and
      provider not in ['koding', 'custom']


  # Return list of providers
  return providers
