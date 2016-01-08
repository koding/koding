Bongo    = require 'bongo'
{ Base } = Bongo

SocialChannel = require './channel'
SocialMessage = require './message'

module.exports = class SocialMessageContainer extends Base
  @share()

  @set
    schema          :
      message       : SocialMessage
      interactions  : Object
      repliesCount  : Number
      replies       : [SocialMessageContainer]
      accountOldId  : String
