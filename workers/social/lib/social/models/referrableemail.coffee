jraphical = require "jraphical"
module.exports = class JReferrableEmail extends jraphical.Module
  JAccount           = require "./account"
  {ObjectId, secure} = require "bongo"

  @share()

  @set
    schema        :
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
    sharedMethods :
      static      : ["getUninvitedEmails", "deleteEmailsForAccount"]
      instance    : ["invite"]

  @create: (clientId, email, callback)->
    JSession = require "./session"
    JSession.fetchSession clientId, (err, session)->
      return callback err  if err

      {username} = session.data
      JAccount.one {"profile.nickname": username}, (err, account)=>
        return callback err  if err
        r = new JReferrableEmail {
          email
          username
        }
        r.save callback

  @getUninvitedEmails: secure (client, callback)->
    query =
      username : client.context.user
      invited  : false
    JReferrableEmail.some query, {}, callback

  @deleteEmailsForAccount: secure (client, callback)->
    @delete client.context.user, callback

  @delete: (username, callback)->
    JReferrableEmail.remove {username}, callback

  invite: (callback)->
    JMail     = require './email'
    shareUrl  = "https://koding.com/?r=#{@username}"
    email     = new JMail
      from    : 'hello@koding.com'
      email   : @email
      replyto : 'hello@koding.com'
      subject : "#{@username} has invited you to Koding!"
      content : "Click here: #{shareUrl}"
    console.log email
    email.save (err)=>
      return callback err  if err
      @update $set: invited: true, callback
