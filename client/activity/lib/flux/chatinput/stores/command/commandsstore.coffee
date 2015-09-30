KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to contain the whole list of available chat input commands
###
module.exports = class ChatInputCommandsStore extends KodingFluxStore

  @getterPath = 'ChatInputCommandsStore'


  getInitialState: ->

    commands = [
      { name : '/search', description : 'Search in this channel' }
    ]

    toImmutable commands

