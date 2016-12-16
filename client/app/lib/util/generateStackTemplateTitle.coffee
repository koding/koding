nick = require './nick'
getPokemonName = require './getPokemonName'

module.exports = generateStackTemplateTitle = (provider) ->

  provider = if provider
  then " #{provider.capitalize()} "
  else ' '

  "#{(getPokemonName() ? nick()).capitalize()}#{provider}Stack"
