Bongo         = require 'bongo'
{ Base }      = Bongo
SocialChannel = require './channel'
SocialMessage = require './message'

module.exports = class SocialChannelContainer extends Base
  @share()

  @set
    schema             :
      channel            : SocialChannel
      isParticipant      : Boolean
      participantCount   : Number
      participantPreview : Array
      lastMessage        : SocialMessage
