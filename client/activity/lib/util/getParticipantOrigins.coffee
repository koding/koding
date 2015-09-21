isMyPost = require 'app/util/isMyPost'

module.exports = getParticipantOrigins = (channel) ->

  { lastMessage, participantsPreview, participantCount } = channel.toJS()

  lastMessageOwner = lastMessage.account

  origins = if isMyPost lastMessage then [] else [lastMessageOwner]

  filtered = participantsPreview.filter (p) ->
    return not (p._id in [whoami()._id, lastMessageOwner._id])

  origins = (origins.concat filtered).slice 0, 3

  return origins.map (origin) -> constructorName: 'JAccount', id: origin._id
