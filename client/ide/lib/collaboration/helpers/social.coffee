kd = require 'kd'
remote = require('app/remote').getInstance()
getNick = require 'app/util/nick'
getCollaborativeChannelPrefix = require 'app/util/getCollaborativeChannelPrefix'

addParticipants = (opts, callback) ->
  kd.singletons.socialapi.channel.addParticipants opts, callback

removeParticipants = (opts, callback) ->
  kd.singletons.socialapi.channel.removeParticipants opts, callback

kickParticipants = (channel, accounts = [], callback) ->
  accounts = [].concat accounts  unless Array.isArray accounts
  opts = { channelId: channel.id, accountIds: accounts.map (a) -> a.socialApiId }
  kd.singletons.socialapi.channel.kickParticipants opts, callback

fetchChannel = (id, callback) ->
  kd.singletons.socialapi.cacheable 'channel', id, callback

destroyChannel = (channel, callback) ->
  {id} = channel
  kd.singletons.socialapi.channel.delete {channelId: id}, callback

leaveChannel = (channel, callback) ->
  options = { channelId: channel.id }
  kd.singletons.socialapi.channel.leave options, callback

initChannel = (callback) ->
  {message} = kd.singletons.socialapi
  nickname  = getNick()

  options =
    type       : 'collaboration'
    body       : "@#{nickname} initiated the IDE session."
    purpose    : "#{getCollaborativeChannelPrefix()}"
    recipients : [ nickname ]
    payload    : {'system-message': 'initiate'}

  message.initPrivateMessage options, (err, channels) ->
    return callback err  if err
    return callback {message: 'error'}  unless channels?.length
    return callback null, channels[0]

fetchAccount = (userId, callback) ->
  remote.cacheable 'JAccount', userId, callback

module.exports = {
  addParticipants
  removeParticipants
  kickParticipants
  fetchChannel
  destroyChannel
  leaveChannel
  initChannel
}
