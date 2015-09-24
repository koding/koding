whoami   = require 'app/util/whoami'
isMyPost = require 'app/util/isMyPost'

module.exports = getParticipantOrigins = (channel) ->

  { lastMessage, participantsPreview, participantCount } = channel.toJS()

  lastMessageOwner = lastMessage?.account

  origins = if lastMessageOwner and not isMyPost(lastMessage) then [lastMessageOwner] else []
  owners  = [whoami()._id]
  owners.push lastMessageOwner._id  if lastMessageOwner

  filtered = participantsPreview.filter (p) ->
    return not (p._id in owners)

  origins = (origins.concat filtered).slice 0, 3

  return origins.map (origin) -> constructorName: 'JAccount', id: origin._id
