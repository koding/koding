immutable    = require 'immutable'
toImmutable  = require 'app/util/toImmutable'
generateDummyMessage = require 'app/util/generateDummyMessage'

module.exports = generateDummyMessages = ({ size }) ->

  messages = immutable.Map()

  [0...size].forEach (i) ->
    message  = toImmutable generateDummyMessage()
    message  = message.set 'id', i
    message  = message.set '_id', i
    messages = messages.set i, message

  return messages
