immutable            = require 'immutable'
toImmutable          = require 'app/util/toImmutable'
generateDummyChannel = require './generateDummyChannel'

module.exports = generateDummyChannels = (size) ->

  channels = immutable.Map()
  options = { typeConstant : 'bot' }
  [0...size].forEach (i) ->
    channel = toImmutable(generateDummyChannel options)
    channel = channel.set 'id', i
    channels = channels.set i, channel

  return channels
