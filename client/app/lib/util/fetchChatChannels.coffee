kd               = require 'kd'
fetchAccount     = require 'app/util/fetchAccount'
isFeatureEnabled = require 'app/util/isFeatureEnabled'

module.exports = (options, callback) ->

  { account, message } = kd.singletons.socialapi

  message.fetchPrivateMessages options, callback

prependParticipantPreview = (channel, account) ->

  origin = { id: account._id, constructorName: 'JAccount', _id: account._id }
  channel.participantCount += 1
  channel.participantsPreview.unshift origin

  return channel
