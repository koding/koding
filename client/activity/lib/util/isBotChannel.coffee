kd = require 'kd'

module.exports = isBotChannel = (id) ->

  botChannel = kd.singletons.socialapi.getPrefetchedData 'bot'

  return id is botChannel.id

