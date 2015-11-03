KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to handle channel mentions
###
module.exports = class ChatInputChannelMentionsStore extends KodingFluxStore

  @getterPath = 'ChatInputChannelMentionsStore'


  getInitialState: ->

    mentions = [
      {
        names       : [ 'channel', 'all', 'team', 'group' ]
        description : 'notify everyone in the channel'
      }
      {
        names       : [ 'admins' ]
        description : 'notify only team admins'
      }
    ]

    return toImmutable mentions

