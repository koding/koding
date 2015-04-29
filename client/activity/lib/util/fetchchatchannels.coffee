kd = require 'kd'
fetchAccount = require 'app/util/fetchaccount'

module.exports = (options, callback) ->

  { account, message } = kd.singletons.socialapi

  # fetch bot channel.
  account.fetchBotChannel (err, botChannel) ->
    return callback err  if err

    # fetch bot account.
    fetchAccount 'bot', (err, botAccount) ->
      return callback err  if err

      prependParticipantPreview botChannel, botAccount

      # append bot to participants preview.
      message.fetchPrivateMessages options, (err, pmChannels) ->
        return callback err  if err

        # finally prepend botChannel to other PM channels and
        # call callback with them
        pmChannels = [botChannel].concat pmChannels
        return callback null, pmChannels


prependParticipantPreview = (channel, account) ->

  origin = { id: account._id, constructorName: 'JAccount', _id: account._id }
  channel.participantCount += 1
  channel.participantsPreview.unshift origin

  return channel

