KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to contain the whole list of available chat input commands
###
module.exports = class ChatInputCommandsStore extends KodingFluxStore

  @getterPath = 'ChatInputCommandsStore'


  getInitialState: ->

    commands = [
      {
        name        : '/s'
        description : 'Search in this channel'
      }
      {
        name        : '/invite'
        description : 'Invite another member to this channel'
        paramPrefix : '@'
        paramText   : '@user'
      }
      {
        name        : '/leave'
        description : 'Leave this channel'
      }
    ]

    toImmutable commands

