jraphical = require 'jraphical'

module.exports = class JInvitation extends jraphical.Module

  @trait __dirname, '../traits/grouprelated'

  fs = require 'fs'
  crypto = require 'crypto'
  nodePath = require 'path'
  {uniq} = require 'underscore'

  {permit} = require './group/permissionset'

  @isEnabledGlobally = yes

  {ObjectRef, dash, daisy, secure} = require 'bongo'

  JAccount = require './account'
  JLimit = require './limit'
  JLimit = require './limit'
  KodingError = require '../error'
  JMail = require './email'

  @share()

  @set
    indexes         :
      code          : 'unique'
    sharedMethods   :
      static        : ['create','byCode','sendBetaInviteFromClient',
                       'grantInvitesFromClient','markAsSent',
                       'betaInviteCount', 'createViaGroup',
                       'createMultiuse' ]
    schema          :
      code          :
        type        : String
        required    : yes
      inviteeEmail  : String
      group         :
        type        : String
        required    : yes
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

  createBetaInvite = (options, callback)->
    {inviterUsername, inviteeEmail, inviteType} = options
    inviterUsername ?= "devrim"
    inviteeEmail    ?= "pleaseChangeThisEmailWithYourOwn+"+Date.now()+"@koding.com"
    inviteType      ?= "koding.com"

    JAccount.one {'profile.nickname': inviterUsername}, (err, inviterAccount)->
      code = crypto
        .createHmac('sha1', 'kodingsecret')
        .update(inviteeEmail+Date.now())
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

  # @markAsSent = secure (client,options,callback)->
  #   account = client.connection.delegate
  #   # unless 'super-admin' in account.globalFlags
  #   unless account?.profile?.nickname is 'devrim'
  #     return callback new KodingError "not authorized"
  #   else
  #     JInvitationRequest = require "./invitationrequest"
  #     options.sort ?= 1
  #     JInvitationRequest.some {sent:$ne:true}, {limit:options.howMany, sort:requestedAt:options.sort}, (err,arr)->
  #       arr.forEach (invitationRequest)->
  #         invitationRequest.update $set:sent:true,(err)->
  #         callback null,"#{invitationRequest.email} is marked as sent."

  @sendBetaInviteFromClient = secure (client, options, callback)->

    unless client.connection.delegate?.can? 'send-invites'
      return callback new KodingError "not authorized"
    else
      JInvitationRequest = require "./invitationrequest"
      options.sort ?= 1
      if options.batch?
        JInvitationRequest.some {sent:$ne:true}, {limit:options.batch, sort:requestedAt:options.sort}, (err, emails)->

          callback null, "Done." if emails.length == 0
          counter = 0
          daisy queue = emails.map (item) -> ->
            continueLooping = ->
              counter += 1
              callback null, "Done." if emails.length == counter
              setTimeout (-> queue.next()), 50

            JInvitation.sendBetaInvite email:item.email,(err,res)->
              if err
                callback err,"#{item.email}:something went wrong sending the invite. not marked as sent."
                continueLooping()
              else
                item.update $set:sent:yes, (err)->
                  if err
                    callback 'err',"#{item.email}something went wrong saving the item as sent."
                  else
                    callback null,"#{item.email} is sent and marked as sent."
                    console.log "#{item.email} is sent and marked as sent."
                  continueLooping()
      else
        JInvitation.sendBetaInvite options,callback

  @betaInviteCount = secure (client, callback)->

    {connection} = client
    unless connection.delegate?.can? 'send-invites'
      callback "You are not authorized to do this."
      console.error "Not authorized request from", connection.delegate?.profile?.nickname
    else
      JInvitationRequest = require "./invitationrequest"
      JInvitationRequest.count {sent:$ne:true}, (err, waitingInvite)->
        if err then callback err
        else callback "There are #{waitingInvite} people who is waiting for invite."


  @sendBetaInvite = do ->
    betaTestersHTML = null
    (options,callback) ->

      betaTestersHTML ?= fs.readFileSync nodePath.join(KONFIG.projectRoot, 'email/beta-testers-invite.txt'), 'utf-8'

      Bitly = require 'bitly'
      bitly = new Bitly KONFIG.bitly.username, KONFIG.bitly.apiKey
      protocol = 'http://'
      email   = options.email ? "devrim+#{Date.now()}@koding.com"

      JInvitation.one {inviteeEmail: email}, (err, invite)=>
        if err
          console.log err
        else if invite?
          url = "#{KONFIG.uri.address}/Invitation/#{invite.code}"
          personalizedMail = betaTestersHTML.replace '#{url}', url#shortenedUrl

          emailerObj =
            from     : @getInviteEmail()
            email    : email
            subject  : '[Koding] Here is your beta invite!'
            content  : personalizedMail

          email = new JMail emailerObj
          email.save (err)->
            unless err then callback null
            else callback err

        else
          createBetaInvite inviteeEmail:email,(err)->
            unless err
              options.email = email
              JInvitation.sendBetaInvite options,callback
            else
              console.log "[JInvitation.sendBetaInvite] something got messed up."

  @grantInvitesFromClient = secure (client, options, callback)->

    unless client.connection.delegate?.can? 'grant-invites'
      return callback new KodingError "not authorized"
    else
      if options.batch?
        callback "not implemented yet"
      else
        {username, quota} = options
        quota = 3 if quota is ''
        @grant {'profile.nickname':username}, quota, (err)->
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

  @getInviteFooter =->
    """
    ------------------
    If you're curious, here is a bit about Koding, http://techcrunch.com/2012/07/24/koding-launch/

    In very short, Koding lets you code, share and have fun.

    notes:
    - of course you can mail us back if you like... (hello@koding.com)
    - this is still beta, expect bugs, please don’t be surprised if you spot one.
    - if you already have an account, you can forward this to a friend.
    - no matter how you signed up, you will not receive any mailings, newsletters and other crap.
    - if you’ve never signed up (sometimes people type emails wrong, and it happens to be yours), please let us know.
    - take a look at http://wiki.koding.com for things you can do.
    - if you fall in love with this project, please let us know - http://blog.koding.com/2012/06/we-want-to-date-not-hire/

    Whole Koding Team welcomes you,
    Devrim, Sinan, Chris, Aleksey, Gokmen, Arvid, Richard and Nelson
    """

  @getInviteSubject =({inviter})-> "#{inviter} has invited you to Koding!"

  @getInviteMessage =({inviter, url, message})->
    message or= "#{inviter} has invited you to Koding!"
    """
    Hi there, we hope this is good news :) because,

    #{message}

    This link will allow you to create an account:
    #{url}

    If you reply to this email, it will go back to your friend who invited you.

    Enjoy! :)

    #{@getInviteFooter()}
    """

  @getSubjectForInviteViaGroup =({inviter, group, isPublic})->
    subject  = "#{inviter} has invited you to #{group}"
    subject += ' on Koding' if isPublic
    subject += '!'

  @getMessageForInviteViaGroup =({inviter, group, isPublic, url})->
    subject  = "#{inviter} has invited you to the group #{group}"
    subject += ' on Koding' if isPublic
    subject += '.'

    message = """
    Hi there,

    #{subject}

    This link will allow you to join the group: #{url}

    If you reply to this email, it will go to #{inviter}.

    Enjoy! :)

    """
    message += @getInviteFooter() if isPublic
    return message

  @byCode = (code, callback)-> @one {code}, callback

  @createMultiuse = permit 'send invitations',
    success: (client, options, callback) ->
      {connection:{delegate}, context:{group}} = client
      {code, maxUses} = options
      invite = new JInvitation {
        code
        group
        maxUses   : maxUses
        type      : 'multiuse'
        origin    : ObjectRef(delegate)
      }
      invite.save (err) ->
        if err then callback err
        else invite.addInvitedBy delegate, (err) -> callback err

  @generateInvitationCode = (email, group)->
    code = crypto.createHmac 'sha1', 'kodingsecret'
    code.update email
    code.update group  if group
    code.digest 'hex'

  @getHostAndProtocol = do->
    {host, protocol} = require('../config').email
    protocol = if host is 'localhost' then 'http:' else 'https:'
    protocol ?= protocol.split(':').shift()+':'
    return {host, protocol}

  @sendInviteEmail = (invite,client,customMessage,limit,callback) ->
    {delegate} = client.connection
    {host, protocol} = @getHostAndProtocol
    messageOptions =
      subject   : customMessage.subject
      body      : customMessage.body
      inviter   : delegate.getFullName()
      url       : "#{protocol}//#{host}/Invitation/#{encodeURIComponent invite.code}"

    JUser = require './user'
    JUser.fetchUser client,(err,inviter)=>

      email = new JMail
        email    : invite.inviteeEmail
        subject  : @getInviteSubject(messageOptions)
        content  : @getInviteMessage(messageOptions)
        replyto  : inviter.email

      email.save (err)->
        limit.update {$inc: usage: 1}, (err)-> console.log err if err
        unless err
          invite.update {$set: status: "sent"}, (err)-> console.log err if err
          callback null
        else
          invite.update {$set: status: "couldnt send email"}, (err)-> console.log err if err
          callback new KodingError "I got your request just couldn't send the email, I'll try again. Consider it done."

  @sendEmailForInviteViaGroup =(client, invite, group, callback)->
    JUser = require './user'
    {delegate} = client.connection
    {host, protocol} = @getHostAndProtocol

    options =
      group    : group.title
      inviter  : delegate.getFullName()
      url      : "#{protocol}//#{host}/#{group.slug}/Invitation/#{encodeURIComponent invite.code}"
      isPublic : if group.privacy == 'public' then true else false

    JUser.fetchUser client, (err, inviter)=>
      email = new JMail
        email   : invite.inviteeEmail
        subject : @getSubjectForInviteViaGroup options
        content : @getMessageForInviteViaGroup options
        replyto : inviter.email

      email.save (err)->
        unless err
          invite.update {$set: status: 'sent'}, (err)-> console.log err if err
          callback null
        else
          invite.update {$set: status: 'couldnt send email'}, (err)-> console.log err if err
          callback new KodingError "I got your request. I just couldn't send the email, I'll try again. Consider it done."

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
          JInvitation.one {"inviteeEmail":email},(err,inv)=>
            if inv
              @sendInviteEmail inv,client,customMessage,limit,callback
            else
              code = @generateInvitationCode email
              invite = new JInvitation {
                code
                customMessage
                maxUses       : 1
                inviteeEmail  : email
                origin        : ObjectRef(delegate)
              }
              invite.save (err)=>
                if err then callback err
                else
                  invite.addInvitedBy delegate, (err)=>
                    if err then callback err
                    else
                      @sendInviteEmail invite,client,customMessage,limit,callback

  # we may find better names for these two methods :) HK
  @createViaGroup = secure (client, group, emails, callback=->)->
    @createViaGroupWithoutNotification client, group, emails, (err, invite)=>
      return callback err  if err
      @sendEmailForInviteViaGroup client, invite, group, callback

  @createViaGroupWithoutNotification = secure (client, group, emails, callback=->)->
    {delegate} = client.connection
    emails.forEach (email)=>
      selector =
        inviteeEmail : email
        group        : group.slug

      JInvitation.one selector, (err, existingInvite)=>
        return callback err   if err
        return callback null  if existingInvite

        code = @generateInvitationCode email, group.slug
        invite = new JInvitation
          code         : code
          maxUses      : 1
          inviteeEmail : email
          origin       : ObjectRef(delegate)
          group        : group.slug

        invite.save (err)=>
          return callback err  if err
          if delegate instanceof JAccount
            invite.addInvitedBy delegate, (err)-> callback err, invite
          else
            callback null, invite

  redeem:secure ({connection:{delegate}}, callback=->)->
    operation = $inc: {uses: 1}
    isRedeemed = if @type is 'multiuse' then @uses + 1 >= @maxUses else yes
    operation.$set = {status: 'redeemed'} if isRedeemed
    @update operation, (err)=>
      return callback err  if err
      @addRedeemer delegate, callback

  markAccepted: secure (client, callback)->
    @redeem client, (err)=>
      return callback err  if err
      JInvitationRequest = require './invitationrequest'
      selector =
        email  : @inviteeEmail
        group  : @group
        status :'sent'
      JInvitationRequest.one selector, (err, request)->
        return callback err  if err or not request
        request.update $set:status:'accepted', callback
