{ Model } = require 'bongo'

module.exports = class JUnsubscribedMail extends Model

  @share()

  @set
    indexes          :
      email          : 'unique'

    schema           :
      email          :
        type         : String
        email        : yes
      unsubscribedAt :
        type         : Date
        default      : -> new Date

  @isUnsubscribed = (email, callback) ->
    @one { email }, (err, unsubscribed) ->
      callback err, unsubscribed?

  @removeFromList = (email, callback = -> ) ->
    @one { email }, (err, unsubscribed) ->
      return callback err                  if err
      return unsubscribed.remove callback  if unsubscribed
      callback null
