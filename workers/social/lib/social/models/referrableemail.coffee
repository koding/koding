jraphical = require "jraphical"
module.exports = class JReferrableEmail extends jraphical.Module
  JAccount = require "./account"
  Tracker  = require "./tracker"

  {ObjectId, secure, signature} = require "bongo"
  {ObjectId, secure} = require "bongo"

  @share()

  @set
    sharedEvents  :
      instance    : [
        { name    : "save" }
      ]
    sharedMethods :
      static      :
        invite    :
          (signature String, Function)
        getUninvitedEmails:
          (signature Function)
        deleteEmailsForAccount:
          (signature Function)
      instance    :
        invite    :
          (signature Function)
    schema        :
      title       : String
      email       :
        type      : String
        email     : yes
      invited     :
        type      : Boolean
        default   : false
      username    : String
      createdAt   :
        type      : Date
        default   : -> new Date
      modifiedAt  :
        type      : Date
        get       : -> new Date

  @create: (clientId, {email, title}, callback)->
    JSession = require "./session"
    JSession.fetchSession clientId, (err, { session })->
      return callback err  if err

      {username} = session.data

      JAccount = require "./account"
      JAccount.one {"profile.nickname": username}, (err, account)=>
        return callback err  if err
        r = new JReferrableEmail {email, title, username}
        r.save callback

  @getUninvitedEmails: secure (client, callback)->
    query      =
      username : client.connection.delegate.profile.nickname
      invited  : false
    JReferrableEmail.some query, {}, callback

  @deleteEmailsForAccount: secure (client, callback)->
    @delete client.context.user, callback

  @delete: (username, callback)->
    JReferrableEmail.remove {username}, callback

  invite: secure (client, callback)->
    {delegate: profile: {firstName, lastName, nickname}} = client.connection

    shareUrl  = "https://koding.com/R/#{@username}"

    Tracker.track nickname, {
      to         : @email
      subject    : Tracker.types.INVITED_GROUP
    }, { firstName, lastName, shareUrl }

    @update $set: invited: true, callback

  @invite: secure (client, email, callback) ->
    {connection: {delegate: {profile: {nickname}}}} = client
    r = new JReferrableEmail {email, username: nickname}
    r.save (err) ->
      return  callback err if err
      r.invite client, callback
