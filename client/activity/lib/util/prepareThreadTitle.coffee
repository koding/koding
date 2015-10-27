React                 = require 'kd-react'
whoami                = require 'app/util/whoami'
getParticipantOrigins = require 'activity/util/getParticipantOrigins'
makeProfileText       = require 'activity/util/makeProfileText'

module.exports = prepareThreadTitle = (thread) ->

  channel = thread.get 'channel'
  name = channel.get 'name'

  if name
    return <span className="Thread-name">{name}</span>

  preview = channel.get 'participantsPreview'
  count   = channel.get 'participantCount'

  shouldBeGrouped = no

  if count is 1
    sample = preview
  else
    # filter out logged in user.
    sample = preview.filter (acc) -> acc.get('_id') isnt whoami()._id
    shouldBeGrouped = yes  if count > 2

  if shouldBeGrouped
    origins = getParticipantOrigins channel
    nameCount = origins.length

    children = []

    origins.forEach (origin, index) ->
      children.push makeProfileText origin
      children.push helper.getSeparatorPartial count, nameCount, index

    children.push helper.getPlusMorePartial count, nameCount  if count > nameCount + 1
  else
    children = makeProfileText sample.get 0

  return children

helper =

  getSeparatorPartial: (participantCount, nameCount, position) ->

    thereIsDifference = !!(participantCount - nameCount - 1)

    switch
      when (nameCount - position) is (if thereIsDifference then 1 else 2)
        return ' & '
      when position < nameCount - 1
        return ', '


  getPlusMorePartial: (participantCount, nameCount) ->
    text = " #{participantCount - nameCount - 1} more"

    return text
