{Model} = require 'bongo'

module.exports = class JChatMessage extends Model

  @set
    schema        :
      channelName : String
      createdAt   :
        type      : Date
        default   : -> new Date
      createdBy   : String
      content     : String
      readAt      : String