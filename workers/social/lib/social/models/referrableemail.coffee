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
    shareUrl  = "https://koding.com/?r=#{@username}"
    email     = new JMail
      from    : 'hello@koding.com'
      email   : @email
      replyto : 'hello@koding.com'
      subject : "#{@username} has invited you to Koding!"
      content : """
        Hi there,

        #{firstName} #{lastName} wants you to try Koding!

        Koding is a new way for developers to work where developers come together and code in the browser – with a real development server to run their code.
        Developers can work, collaborate, write and run apps without jumping through hoops and spending unnecessary money.

        Click here to try: #{shareUrl}

        See you on Koding
        """

    email.save (err)=>
      return callback err  if err
      @update $set: invited: true, callback
