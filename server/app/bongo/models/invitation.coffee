class JInvitation extends jraphical.Module
  
  crypto = require 'crypto'
  {uniq} = require 'underscore'
  
  @isEnabledGlobally = yes
  
  {ObjectRef, dash, daisy} = bongo
  
  @share()
  
  @set
    indexes         :
      code          : 'unique'
    sharedMethods   :
      static        : ['create','byCode','__sendBetaInvites'] # ,'__createBetaInvites'
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
        enum        : ['invalid invitation type', ['personal','multiuse','launchrock']]
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
  
  # @__attemptToFixChrisFuckup =(callback)->
  #   i = 0
  #   JAccount.one {'profile.nickname': 'devrim'}, (err, devrim)=>
  #     if err
  #       callback err
  #     else
  #       @all { 'origin.constructorName': $exists: no }, (err, invites)->
  #         invites.forEach (invite)->
  #           if err
  #             callback err
  #           else
  #             invite.update {$set: origin: ObjectRef devrim}, {multi: yes}, callback
  #             # invite.addInvitedBy devrim, (err)->
  #             #   console.log err
  #             #   console.log 'finished', i++
  #             #   callback 'ok'
  # 
  @__sendBetaInvites = bongo.secure do->
    betaTestersEmails = fs.readFileSync 'invitee-emails2.txt', 'utf-8'
    # betaTestersEmails = 'chris123412341234@jraphical.com'
    betaTestersHTML   = fs.readFileSync 'email/beta-testers-invite.txt', 'utf-8'
    protocol = 'https://'
    (client,callback)->
      i = 0
      recipients = []
      {host, port} = server
      account = client.connection.delegate
      unless 'super-admin' in account.globalFlags 
        return callback new KodingError "not authorized"

      # host = 'localhost:3000'
      # protocol = 'http://'
      uniq(betaTestersEmails.split '\n').slice(1000, 1999).forEach (email)=>
        recipients.push =>
          @one {inviteeEmail: email}, (err, invite)=>
            if err
              console.log err
            else if invite?
              url = "#{protocol}#{host}/invitation/#{invite.code}"
              # bitly.shorten url, (err, response)=>
              #   shortenedUrl = response.data.url
              #   if shortenedUrl?
                  # shortenedUrl = url
              personalizedMail = betaTestersHTML.replace '#{url}', url#shortenedUrl
              
              Emailer.send
                From      : @getInviteEmail()
                To        : email
                Subject   : '[Koding] Here is your beta invite!'
                TextBody  : personalizedMail
              , (err)-> 
                # console.log 'finished', i++, err
                recipients.next(err)
                # else console.log email
            else
              console.log "no invitation was found for #{email}"              
              recipients.next null
      recipients.push callback
      daisy recipients
        
  
  @__createBetaInvites =do ->
    #betaTestersEmails = 'chris123412341234@jraphical.com'
    betaTestersEmails = fs.readFileSync('./invitee-emails2.txt', 'utf-8')
    #betaTestersEmails = 'chris123123@jraphical.com'
    (callback)->
      JAccount.one {'profile.nickname': 'devrim'}, (err, devrim)=>
        i = 0
        recipients = []
        uniq(betaTestersEmails.split '\n').forEach (email)->
          code = crypto
            .createHmac('sha1', 'kodingsecret')
            .update(email)
            .digest('hex')
          # console.log email, code
          recipients.push ->
            invite = new JInvitation {
              code
              inviteeEmail  : email
              maxUses       : 1
              origin        : ObjectRef(devrim)
              type          : 'launchrock'
            }
            invite.save (err)-> 
              recipients.next(err)
        recipients.push -> callback(recipients)
        daisy recipients
  
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
  
  @__createMultiuse = bongo.secure (client, options, callback)->
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
  
  @create = bongo.secure (client, options, callback)->
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
                  {host, port} = server
                  protocol = if host is 'localhost' then 'http://' else 'https://'
                  messageOptions =
                    subject   : customMessage.subject
                    body      : customMessage.body
                    inviter   : delegate.getFullName()
                    url       : "#{protocol}#{host}/invitation/#{encodeURIComponent code}"

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
  
  redeem:bongo.secure ({connection:{delegate}}, callback=->)->
    operation = $inc: {uses: 1}
    isRedeemed = if @type is 'multiuse' then @uses + 1 >= @maxUses else yes
    operation.$set = {status: 'redeemed'} if isRedeemed
    @update operation, (err)=>
      if err
        callback err
      else
        @addRedeemer delegate, (err)-> callback err
