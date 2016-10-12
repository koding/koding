nick = require './nick'

module.exports = generateStackTemplateTitle = (provider) ->

  provider = if provider
  then " #{provider} "
  else ''

  "#{nick().capitalize()}'s#{provider}Stack"
