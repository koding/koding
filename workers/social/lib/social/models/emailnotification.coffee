{Model} = require 'bongo'

module.exports = class JEmailNotification extends Model

  @setSchema
    timestamp :
      type    : Date
      default : -> new Date
    email     : String
    receiver  : Object
    event     : String
    contents  : Object
    status    :
      type    : String
      default : 'queued'
      enum    : ['Invalid status',['queued','attempted']]

  constructor:(email, receiver, event, contents)->
    super {email, receiver, event, contents}