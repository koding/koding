kd = require 'kd'
helper = require '../helper'

###*
 * Base class for representing a video participant.
 * OpenTok has 2 different idea of users. `Publisher` and `Subscriber`.
 * `Publisher` is logged in user. `Subscriber`s are other users that are
 * connected to OpenTok session.
 *
 * This class acts as an Abstract class and is not even exported.
 * @see {Publisher}
 * @see {Subscriber}
 *
 * @class ParticipantType.BaseVideoParticipant
###
class BaseVideoParticipant extends kd.EventEmitter

  constructor: (nick, videoData) ->

    # call KDEventEmitter constructor with an empty object to make it start
    # working.
    super {}

    @nick = nick
    @videoData = videoData
    @type = null

    helper.subscribeToAudioChanges @videoData,
      started : => @emit 'TalkingDidStart'
      stopped : => @emit 'TalkingDidStop'


  getType: -> @type


###*
 * Transformation from OpenTok Publisher -> Koding ChatVideoPublisher
 *
 * @class ParticipantType.Publisher
###
class Publisher extends BaseVideoParticipant

  constructor: (nick, videoData) ->
    super nick, videoData
    @type = 'publisher'


###*
 * Transformation from OpenTok Subscriber -> Koding ChatVideoSubscriber
 *
 * @class ParticipantType.Subscriber
###
class Subscriber extends BaseVideoParticipant

  constructor: (nick, videoData) ->
    super nick, videoData
    @type = 'subscriber'



module.exports = participantTypes = { Publisher, Subscriber }

