kd               = require 'kd'
fetchAccount     = require 'app/util/fetchAccount'
isFeatureEnabled = require 'app/util/isFeatureEnabled'

module.exports = (options, callback) ->

  { account, message } = kd.singletons.socialapi

  message.fetchPrivateMessages options, (err, pmChannels) ->
    return callback err  if err

    return callback null, pmChannels  unless isFeatureEnabled 'botchannel'

    # fetch bot channel.
    account.fetchBotChannel (err, botChannel) ->

      # if there is an error in the botChannel fetch, return all the channels
      # that has been fetched before.
      return callback null, pmChannels  if err

      # fetch bot account.
      fetchAccount 'bot', (err, botAccount) ->
        return callback err  if err

        prependParticipantPreview botChannel, botAccount

        # append bot to participants preview.

        # finally prepend botChannel to other PM channels and
        # call callback with them
        pmChannels = [botChannel].concat pmChannels
        return callback null, pmChannels


prependParticipantPreview = (channel, account) ->

  origin = { id: account._id, constructorName: 'JAccount', _id: account._id }
  channel.participantCount += 1
  channel.participantsPreview.unshift origin

  return channel
