{
  thread: threadActions, channel: channelActions, message: messageActions
} = require('activity/flux').actions

module.exports = changeToChannel = (channel, postId, callback) ->

  threadActions.changeSelectedThread channel.id
  channelActions.loadParticipants channel.id

  if postId
  then messageActions.changeSelectedMessage postId
  else messageActions.changeSelectedMessage null

  callback?()
