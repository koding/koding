dummyChannel = require './generateDummyChannel'
dummyMessage = require './generateDummyMessage'

module.exports = ({ channelId, channel, messages, flags }) ->

  channelId   = channelId or 'dummyChannel-12345'

  return {
    channelId : channelId
    channel   : channel or dummyChannel(channelId)
    flags     : flags or {}
    messages  : [ dummyMessage() ]
  }
