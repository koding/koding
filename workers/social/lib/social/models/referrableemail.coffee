jraphical = require "jraphical"
module.exports = class JReferrableEmail extends jraphical.Module
  JAccount           = require "./account"
  {ObjectId, secure} = require "bongo"

  @share()

  @set
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
    sharedMethods :
      static      : ["getUninvitedEmails", "deleteEmailsForAccount"]
      instance    : ["invite"]

  @create: (clientId, {email, title}, callback)->
    JSession = require "./session"
    JSession.fetchSession clientId, (err, session)->
      return callback err  if err

      {username} = session.data
      JAccount.one {"profile.nickname": username}, (err, account)=>
        return callback err  if err
        r = new JReferrableEmail {email, title, username}
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

  invite: secure (client, callback)->
    {delegate: profile: {firstName, lastName}} = client.connection
    JMail     = require './email'
    shareUrl  = "https://koding.com/R/#{@username}"
    email     = new JMail
      from    : 'hello@koding.com'
      email   : KONFIG.emailWorker.forcedRecipient or @email
      replyto : 'hello@koding.com'
      subject : "#{firstName} #{lastName} has invited you to try Koding!"
      content : """
        Koding is a new way for developers to work where developers come together and code in the browser – with a real development server to run their code.

        Click here to try: #{shareUrl}

        See you on Koding!
        """

    email.save (err)=>
      return callback err  if err
      @update $set: invited: true, callback
