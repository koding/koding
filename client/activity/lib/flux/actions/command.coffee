kd             = require 'kd'
channelActions = require './channel'
getGroup       = require 'app/util/getGroup'


cleanUsername = (name) -> if name.indexOf('@') is 0 then name.substring(1) else name


executeCommand = (command, channel) ->

  channelId        = channel.get 'id'
  { name, params } = command

  switch name
    when '/invite'
      usernames = (cleanUsername param for param in params)
      channelActions.addParticipantsByNames channelId, usernames
    when '/leave'
      if channel.get('typeConstant') is 'privatemessage'
        channelActions.leavePrivateChannel(channelId).then ->
          channelName = getGroup().slug
          kd.singletons.router.handleRoute "/Channels/#{channelName}"
      else
        channelActions.unfollowChannel channelId


module.exports = {
  executeCommand
}

