KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

module.exports = class ChatInputCommandsStore extends KodingFluxStore

  @getterPath = 'ChatInputCommandsStore'


  getInitialState: ->

    commands = [
      { name : '/s', description : 'Search in this channel' }
    ]

    toImmutable commands

