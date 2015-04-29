kd = require 'kd'

module.exports = fetchChannelMessages = (options, callback) ->

  kd.singletons.socialapi.channel.fetchActivities options, callback
