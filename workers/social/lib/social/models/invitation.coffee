jraphical = require 'jraphical'

module.exports = class JInvitation extends jraphical.Module

  fs = require 'fs'
  crypto = require 'crypto'
  nodePath = require 'path'
  {uniq} = require 'underscore'

  Emailer = require '../emailer'

  @isEnabledGlobally = yes

  {ObjectRef, dash, daisy, secure} = require 'bongo'

  JAccount = require './account'
  JLimit = require './limit'
  JLimit = require './limit'

  @share()

  @set
    indexes         :
      code          : 'unique'
    sharedMethods   :
      static        : ['create','byCode','sendBetaInviteFromClient','grantInvitesFromClient']
    schema          :
      code          : String
      inviteeEmail  : String
      customMessage :
        subject     : String
        body        : String
      uses          :
        type        : Number
        default     : 0
      maxUses       :
        type        : Number
        default     : 0
      type          :
        type        : String
        enum        : ['invalid invitation type', ['personal','multiuse','launchrock','koding.com','kodingen.com']]
        default     : 'personal'
      status        :
        type        : String
        enum        : ['invalid status type', ['sent','active','blocked','redeemed','couldnt send email']]
        default     : 'active' # 'unconfirmed'
      origin        : ObjectRef
    relationships   :
      invitedBy     :
        targetType  : JAccount
        as          : 'inviter'
      redeemer      :
        targetType  : JAccount
        as          : 'redeemer'


  createBetaInvite = (options,callback)->
    {inviterUsername,inviteeEmail,inviteType} = options
    inviterUsername ?= "devrim"
    inviteeEmail    ?= "pleaseChangeThisEmailWithYourOwn+"+Date.now()+"@koding.com"
    inviteType      ?= "koding.com"

    JAccount.one {'profile.nickname': inviterUsername}, (err, inviterAccount)->
      code = crypto
        .createHmac('sha1', 'kodingsecret')
        .update(inviteeEmail)
        .digest('hex')


      invite = new JInvitation
        code          : code
        inviteeEmail  : inviteeEmail
        maxUses       : 1
        origin        : ObjectRef(inviterAccount)
        type          : inviteType

      invite.save (err)->
        if err
          console.log err
          callback err
        else
          callback null

  @sendBetaInviteFromClient = secure (client, options,callback)->
    console.log "im called"
    JInvitationRequest = require "./invitationrequest"
    account = client.connection.delegate
    # unless 'super-admin' in account.globalFlags
    unless account?.profile?.nickname is 'devrim'
      return callback new KodingError "not authorized"
    else
      if options.batch?
        JInvitationRequest.some {sent:$ne:true}, {limit:options.batch, sort:requestedAt:-1},(err,emails)->
          daisy queue = emails.map (item)->
            ->
              continueLooping = ->
                setTimeout (-> queue.next()), 50
              item.sent = yes
              JInvitation.sendBetaInvite email:item.email,(err,res)->
                if err
                  callback err,"#{item.email}:something went wrong sending the invite. not marked as sent."
                  continueLooping()
                else
                  item.save (err)->
                    if err
                      callback 'err',"#{item.email}something went wrong saving the item as sent."
                    else
                      callback null,"#{item.email} is sent and marked as sent."
                    continueLooping()

      else
        JInvitation.sendBetaInvite options,callback
  betaTestersHTML   = fs.readFileSync nodePath.join(KONFIG.projectRoot, 'email/beta-testers-invite.txt'), 'utf-8'
  @sendBetaInvite = (options,callback) ->
    Bitly = require 'bitly'
    bitly = new Bitly KONFIG.bitly.username, KONFIG.bitly.apiKey
    protocol = 'http://'
    email   = options.email ? "devrim+#{Date.now()}@koding.com"
    
    JInvitation.one {inviteeEmail: email}, (err, invite)=>
      if err
        console.log err
      else if invite?
        url = "#{KONFIG.uri.address}/invitation/#{invite.code}"
        personalizedMail = betaTestersHTML.replace '#{url}', url#shortenedUrl

        emailerObj =
          From      : @getInviteEmail()
          To        : email
          Subject   : '[Koding] Here is your beta invite!'
          TextBody  : personalizedMail

        # console.log emailerObj
        if options.justInviteNoEmail
          callback null,"invite link: #{url}"
          bitly.shorten url, (err, response)->
            if err
              callback err
            else
              shortenedUrl = response.data.url
              callback err,shortenedUrl
        else
          Emailer.send emailerObj, (err)->
            if err
              console.log '[ERROR SENDING MAIL]', email,err
              callback err
            else
              callback null
          # else console.log email
      else
        # console.log "no invitation was found for #{email}"
        createBetaInvite inviteeEmail:email,(err)->
          unless err
            options.email = email
            JInvitation.sendBetaInvite options,callback
          else
            log "[JInvitation.sendBetaInvite] something got messed up."

  @grantInvitesFromClient = secure (client, options,callback)->
    account = client.connection.delegate
    # unless 'super-admin' in account.globalFlags
    unless account?.profile?.nickname is 'devrim'
      return callback new KodingError "not authorized"
    else
      if options.batch?
        callback "not implemented yet"
      else
        {username,quota} = options
        quota = 3 if quota is ''
        @grant {'profile.nickname':username},quota,(err)->
          if err
            callback err
          else
            callback null, "#{quota} invites granted to #{username}"


  @grant =(selector, quota, callback)->
    unless quota > 0
      callback new KodingError "Quota must be positive."
    else
      batch = []
      JAccount.all selector, (err, accounts)->
        for account in accounts
          batch.push ->
            account.fetchLimit 'invite', (err, limit)->
              if err then batch.fin(err)
              else if limit
                limit.update $inc: {quota}, (err)-> batch.fin(err)
              else
                limit = new JLimit {quota}
                limit.save (err)->
                  if err
                    batch.fin(err)
                  else
                    account.addLimit limit, 'invite', (err)-> batch.fin(err)
        dash batch, callback

  @getInviteEmail =-> "hello@koding.com"

  @getInviteSubject =({inviter})-> "#{inviter} has invited you to Koding!"

  @getInviteMessage =({inviter, url, message})->
    message or= "#{inviter} has invited you to Koding!"
    """
    Hi there,

    #{message}

    This URL will allow you to create an account:
    #{url}
    """

  @byCode = (code, callback)-> @one {code}, callback

  @__createMultiuse = secure (client, options, callback)->
    {delegate} = client.connection
    {code, maxUses} = options
    invite = new JInvitation {
      code
      maxUses   : maxUses
      type      : 'multiuse'
      origin    : ObjectRef(delegate)
    }
    invite.save (err)->
      if err
        callback err
      else
        invite.addInvitedBy delegate, callback

  @create = secure (client, options, callback)->
    {delegate} = client.connection
    {emails, subject, customMessage, type} = options
    delegate.fetchLimit 'invite', (err, limit)=>
      if err
        callback err
      else if !limit? or limit? and emails.length > limit.getValue()
        callback new KodingError "You don't have enough invitation quota"
      else
        emails.forEach (email)=>
          code = crypto
            .createHmac('sha1', 'kodingsecret')
            .update(email)
            .digest('hex')
          invite = new JInvitation {
            code
            customMessage
            maxUses       : 1
            inviteeEmail  : email
            origin        : ObjectRef(delegate)
          }
          invite.save (err)=>
            if err
              callback err
            else
              invite.addInvitedBy delegate, (err)=>
                if err
                  callback err
                else
                  {host, protocol} = require('../config').email
                  protocol = if host is 'localhost' then 'http:' else 'https:'
                  protocol ?= protocol.split(':').shift()+':'
                  messageOptions =
                    subject   : customMessage.subject
                    body      : customMessage.body
                    inviter   : delegate.getFullName()
                    url       : "#{protocol}//#{host}/invitation/#{encodeURIComponent code}"

                  JUser = require './user'
                  JUser.fetchUser client,(err,user)=>
                    inviterEmail = user.email

                    Emailer.send
                      From      : @getInviteEmail()
                      To        : email
                      Subject   : @getInviteSubject(messageOptions)
                      TextBody  : @getInviteMessage(messageOptions)
                      ReplyTo   : inviterEmail
                    , (err)->
                      unless err
                        callback null
                        limit.update {$inc: usage: 1}, (err)-> console.log err if err
                        invite.update {$set: status: "sent"}, (err)-> console.log err if err
                      else
                        limit.update  {$inc: usage: 1}, (err)-> console.log err if err
                        invite.update {$set: status: "couldnt send email"}, (err)-> console.log err if err
                        callback new KodingError "I got your request just couldn't send the email, I'll try again. Consider it done."

  redeem:secure ({connection:{delegate}}, callback=->)->
    operation = $inc: {uses: 1}
    isRedeemed = if @type is 'multiuse' then @uses + 1 >= @maxUses else yes
    operation.$set = {status: 'redeemed'} if isRedeemed
    @update operation, (err)=>
      if err
        callback err
      else
        @addRedeemer delegate, (err)-> callback err
