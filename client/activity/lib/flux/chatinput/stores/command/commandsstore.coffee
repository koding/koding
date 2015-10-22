KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to contain the whole list of available chat input commands
###
module.exports = class ChatInputCommandsStore extends KodingFluxStore

  @getterPath = 'ChatInputCommandsStore'


  getInitialState: ->

    commands = [
      {
        name        : '/search'
        description : 'Search in this channel'
        extraInfo   : '(or /s) anything'
      }
      {
        name        : '/invite'
        description : 'Invite another member to this channel'
        paramPrefix : '@'
        extraInfo   : '@user'
      }
      {
        name        : '/leave'
        description : 'Leave this channel'
      }
    ]

    toImmutable commands

