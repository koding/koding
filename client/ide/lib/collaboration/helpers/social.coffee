kd = require 'kd'
remote = require('app/remote').getInstance()
getNick = require 'app/util/nick'
getCollaborativeChannelPrefix = require 'app/util/getCollaborativeChannelPrefix'

###*
 * Wrapper function around `SocialApiController#addParticipants`
 *
 * @param {object} opts
 * @param {function(err: object)}
###
addParticipants = (opts, callback) ->

  kd.singletons.socialapi.channel.addParticipants opts, callback


###*
 * Wrapper function around `SocialApiController#removeParticipants`
 *
 * @param {object} opts
 * @param {function(err: object)}
###
removeParticipants = (opts, callback) ->

  kd.singletons.socialapi.channel.removeParticipants opts, callback


###*
 * Wrapper function around `SocialApiController#kickParticipants`
 *
 * @param {object} opts
 * @param {function(err: object)}
###
kickParticipants = (channel, accounts, callback) ->

  return callback 'accounts are missing'  unless accounts

  accounts = [].concat accounts  unless Array.isArray accounts

  opts = { channelId: channel.id, accountIds: accounts.map (a) -> a.socialApiId }
  kd.singletons.socialapi.channel.kickParticipants opts, callback


###*
 * Wrapper function around `SocialApiController#fetchChannel`
 *
 * @param {object} opts
 * @param {function(err: object)}
###
fetchChannel = (id, callback) ->

  kd.singletons.socialapi.cacheable 'channel', id, callback


###*
 * Wrapper function around `SocialApiController#destroyChannel`
 *
 * @param {SocialChannel} channel
 * @param {function(err: object)}
###
destroyChannel = (channel, callback) ->

  {id} = channel
  kd.singletons.socialapi.channel.delete {channelId: id}, callback


###*
 * Wrapper function around `SocialApiController#channel.listParticipants`
 *
 * One difference is instead of returning simple objects,
 * it transforms them into `JAccount` objects.
 *
 * @param {SocialChannel} channel
 * @param {function(err: object, accounts: Array)}
###
fetchParticipants = (id, callback) ->

  {socialapi} = kd.singletons

  socialapi.channel.listParticipants {channelId: id}, (err, participants) ->
    return callback err  if err

    idList = participants.map ({accountId}) -> accountId
    query  = { socialApiId: { $in: idList } }

    remote.api.JAccount.some query, {}, callback


###*
 * Wrapper function around `SocialApiController#leaveChannel`
 *
 * @param {SocialChannel} channel
 * @param {function(err: object)}
###
leaveChannel = (channel, callback) ->

  options = { channelId: channel.id }
  kd.singletons.socialapi.channel.leave options, callback


###*
 * Wrapper function around `SocialApiController#initChannel`
 *
 * Difference is it sets `collaboration` defaults.
 *
 * @param {function(err: object, result: object)}
###
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


###*
 * Sends an activation message to given channel.
 *
 * @param {SocialChannel} channel
 * @param {function(err:object, result: object)} callback
###
sendActivationMessage = (channel, callback) ->

  {message} = kd.singletons.socialapi
  nickname  = getNick()

  options =
    body       : "@#{nickname} activated collaboration."
    channelId  : channel.id
    payload    :
      'system-message' : 'start'
      collaboration    : yes

  message.sendPrivateMessage options, callback


###*
 * Wrapper function around `JAccount#cacheable`
 * It adds a little bit of intelligence around first
 * argument so that, it will fetch the account depending
 * on some other situations.
 *
 * @param {object|string} socialAccount - either bongo constructor or a user id.
 * @param {function(err: object)}
###
fetchAccount = (socialAccount, callback) ->

  if socialAccount.constructorName
    remote.cacheable socialAccount.constructorName, socialAccount.id, callback
  else if 'string' is typeof socialAccount
    remote.cacheable socialAccount, (err, [account]) -> callback err, account
  else
    callback null, socialAccount


module.exports = {
  fetchParticipants
  addParticipants
  removeParticipants
  kickParticipants
  fetchChannel
  destroyChannel
  leaveChannel
  initChannel
  sendActivationMessage
  fetchAccount
}
