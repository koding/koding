whoami   = require 'app/util/whoami'
isMyPost = require 'app/util/isMyPost'

module.exports = getParticipantOrigins = (channel) ->

  { lastMessage, participantsPreview, participantCount } = channel.toJS()

  isLastMessageOwnerLeave = lastMessage.payload?.systemType? and lastMessage.payload?.systemType  is 'leave'

  lastMessageOwner = lastMessage?.account


  if lastMessageOwner and not isMyPost(lastMessage) and not isLastMessageOwnerLeave
  then origins = [lastMessageOwner]
  else origins = []

  owners  = [whoami()._id]
  owners.push lastMessageOwner._id  if lastMessageOwner and not isLastMessageOwnerLeave

  filtered = participantsPreview.filter (p) ->
    return not (p._id in owners)

  origins = (origins.concat filtered).slice 0, 3

  return origins.map (origin) -> constructorName: 'JAccount', id: origin._id
