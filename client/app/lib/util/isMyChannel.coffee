whoami = require './whoami'

module.exports = (channel) ->
  channel.creatorId is whoami().socialApiId
