kd             = require 'kd'
actionTypes    = require './actiontypes'
Getters        = require 'activity/flux/getters'
MessageActions = require 'activity/flux/actions/message'
whoami         = require 'app/util/whoami'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Sets edit mode for last message in current thread
###
setLastMessageEditMode = ->

  { reactor } = kd.singletons

  accountId = whoami()._id
  thread    = reactor.evaluate Getters.selectedChannelThread
  messages  = thread.get 'messages'
  channelId = thread.get 'channelId'

  lastMessage = messages.findLast (message) ->
    message.getIn(['account', '_id']) is accountId and
    message.get('typeConstant') isnt 'system'

  return  unless lastMessage

  MessageActions.setMessageEditMode lastMessage.get('_id'), channelId


module.exports = {
  setLastMessageEditMode
}
