immutable = require 'immutable'

module.exports = isPublicChatChannel = (channel) ->

  if immutable.Iterable.isIterable channel
  then channel.getIn(['payload', '__publicChat'])?
  else channel.payload.__publicChat?

