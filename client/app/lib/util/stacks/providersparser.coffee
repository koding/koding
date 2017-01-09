module.exports = providersParser = (content, supportedProviders) ->

  content   = content.replace /#.+/igm, ''
  regex     = /\$\{var\.(\w+?)\_/g
  providers = {}
  match     = regex.exec content

  while match
    providers[match[1]] = null
    match = regex.exec content

  unless supportedProviders
    globals = require 'globals'
    supportedProviders = globals.config.providers._getSupportedProviders()

  providers = (Object.keys providers)
    .filter (provider) ->
      provider is 'userInput' or
      provider in supportedProviders and
      provider not in ['koding', 'custom']

  if not providers.length or (providers.length is 1 and providers[0] is 'userInput')
    for provider in supportedProviders
      providers.push provider  if ///#{provider}\_///g.test content

  # Return list of providers
  return providers
