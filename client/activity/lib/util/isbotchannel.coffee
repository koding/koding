kd = require 'kd'

module.exports = isBotChannel = (id) ->

  # TODO: replace this comparison with dynamic koding bot channel id.
  # for eg.
  # botChannel = socialapi.getPrefetchedData 'bot'
  # return id is botChannel.id
  id is '5997928589419347971'

