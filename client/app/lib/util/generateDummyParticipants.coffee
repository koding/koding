immutable    = require 'immutable'
toImmutable  = require 'app/util/toImmutable'
mockjaccount = require '../../../mocks/mock.jaccount'

module.exports = generateParticipants = ({ size }) ->

  participants = immutable.Map()

  [0...size].forEach (i) ->
    participant  = toImmutable mockjaccount
    participant  = participant.set '_id', i
    participants = participants.set i, participant

  return participants
