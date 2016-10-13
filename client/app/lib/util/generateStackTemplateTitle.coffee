nick = require './nick'
pokemon = require 'pokemon-random-name'

module.exports = generateStackTemplateTitle = (provider) ->

  provider = if provider
  then " #{provider.capitalize()} "
  else ' '

  "#{(pokemon() ? nick()).capitalize()}#{provider}Stack"
