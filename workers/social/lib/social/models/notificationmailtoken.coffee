{Model, ObjectId, signature} = require 'bongo'
KodingError = require '../error'

module.exports = class JNotificationMailToken extends Model

  @share()

  @set
    sharedMethods         :
      static              :
        unsubscribeWithId :
          (signature String, String, String, Function)
    schema              :
      notificationType  : String
      unsubscribeId     : String
      recipient         : ObjectId


  flags =
    comment        : 'comment'
    likeActivities : 'like'
    followActions  : 'follow'
    groupJoined    : 'group join'
    groupLeft      : 'group leave'
    mention        : 'mention'
    # not active notification types
    privateMessage : 'private message'
    groupInvite    : 'group invite'
    groupRequest   : 'group request'
    groupApproved  : 'group approval'

  @unsubscribeWithId = (unsubscribeId, email, opt, callback)->
    JNotificationMailToken.one {unsubscribeId}, (err, token)->
      return callback err  if err
      return callback new KodingError 'Invalid unsubscription id'  unless token

      JUser = require './user'
      JUser.one {_id: token.recipient}, (err, user)->
        return callback err  if err
        return callback new KodingError 'User not found'  unless user

        if user.email isnt email
            return callback new KodingError 'Unsubscription token does not match given email.'

        user.fetchOwnAccount (err, account)->
          return callback err  if err
          return callback new KodingError 'Account not found'  unless account

          prefs = {}
          definition = flags[token.notificationType]
          result =
          switch opt
            when 'all'
              prefs.global = false
              definition = ""
            when 'daily' then prefs.daily = false
            else prefs[token.notificationType] = false

          account.setEmailPreferences user, prefs, (err)->
            return callback err  if err

            callback null, "You will no longer get #{definition} notification e-mails"