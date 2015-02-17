getCollaborativeChannelPrefix = require './getCollaborativeChannelPrefix'

module.exports = (channel) ->

  return no  unless channel.purpose?

  prefix = getCollaborativeChannelPrefix()
  return channel.purpose.slice(0, prefix.length) is prefix
