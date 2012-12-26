module.exports = class EmailNotification

  Emailer      = require './emailer'
  KodingError  = require './error'
  flags        =
    privateMessage    :
      messageTemplate : """When someone send me a private message"""
    followActions     :
      messageTemplate : """When someone followed me"""
    comment           :
      messageTemplate : """When a comment related with me"""
    likeActivities    :
      messageTemplate : """When someone liked my activities"""
    likeComments      :
      messageTemplate : """When someone liked my comments"""

  @send:(args, callback)->

    {account, actor, data} = args

    console.log args

    JUser = require './models/user'
    JUser.one {username: account.profile.nickname}, (err, user)->
      unless err
        emailPrefs = user.getAt 'emailFrequency' or {}
        dataType = 'likeActivities'
        if emailPrefs?.global isnt 'instant' or emailPrefs[dataType] isnt 'instant'
          console.log "User disabled e-mail notifications"
          callback null
        else
          console.log "Not implemented yet."
          callback null
      else
        callback new KodingError "User not found"
