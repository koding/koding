jraphical = require 'jraphical'
Bongo     = require "bongo"

{secure, daisy, Base, signature} = Bongo

module.exports = class JInvitation extends jraphical.Module

  @trait __dirname, '../traits/grouprelated'
  @trait __dirname, '../traits/protected'

  fs       = require 'fs'
  crypto   = require 'crypto'
  nodePath = require 'path'
  createId = require 'hat'
  {uniq}   = require 'underscore'

  {permit} = require './group/permissionset'

  @isEnabledGlobally = yes

  {ObjectRef, dash, daisy, secure, signature} = require 'bongo'

  KodingError  = require '../error'
  JMail        = require './email'
  JGroup       = require './group'
  JPaymentPack = require './payment/pack'

  @share()

  @set
    permissions     :
      'send invitations'                  : ['moderator', 'admin']
    indexes         :
      code          : 'unique'
    sharedMethods   :

      instance:
        modifyMultiuse:
          (signature Object, Function)
        remove:
          (signature Function)

      static:
        inviteFriend:
          (signature Object, Function)
        create:
          (signature String, String, Object, Function)
        byCode:
          (signature String, Function)
        suggestCode: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Function, Number)
        ]
        createMultiuse:
          (signature Object, Function)
#        createForResurrection:
#          (signature String, Function)
#        createMultiForResurrection:
#          (signature [String], Function)
#        byCodeForBeta:
#          (signature String, Function)

    sharedEvents    :
      static        : []
      instance      : []
    schema          :
      code          :
        type        : String
        required    : yes
      email         : String
      username      : String
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
        default     : 1
      type          :
        type        : String
        enum        : ['invalid invitation type', ['friend','admin','multiuse']]
        default     : 'admin'
      status        :
        type        : String
        enum        : ['invalid status type', [
          'sent','active','blocked','redeemed','couldnt send email','accepted','ignored'
        ]]
        default     : 'active'
      origin        : ObjectRef
      memo          : String
      createdAt     :
        type        : Date
        default     : -> new Date
    relationships   :
      invitedBy     :
        targetType  : 'JAccount'
        as          : 'inviter'
      redeemer      :
        targetType  : 'JAccount'
        as          : 'redeemer'

  remove$: permit 'send invitations',
    success: (client, callback=->)-> @remove callback

  @byCode = (code, callback)-> @one {code}, callback

  @byCodeForBeta = (code, callback)->
    @one {code, group:"resurrection"}, callback

  @generateInvitationCode = (type, email, group)->
    code = crypto.createHmac 'sha1', 'kodingsecret'
    code.update type
    code.update email
    code.update group  if group
    code.digest 'hex'

  @getHostAndProtocol = do->
    {host, protocol} = require('../config').email
    protocol = if host is 'localhost' then 'http:' else 'https:'
    protocol ?= protocol.split(':').shift()+':'
    return {host, protocol}

  redeem$: secure ({connection:{delegate}}, callback=->)->
    @redeem delegate, callback

  redeem: (account, callback) ->
    operation = $inc: uses: 1

    if @type is 'multiuse'
      isRedeemed = @uses + 1 >= @maxUses
    else
      isRedeemed = yes
    operation.$set = status: 'redeemed'  if isRedeemed

    JGroup.one slug: @group, (err, group) =>
      return callback err  if err
      group.fetchSubscription (err, subscription) =>
        return callback err  if err
        return callback new KodingError "Subscription is not found"  unless subscription
        subscription.debitPack tag: "user", (err) =>
          return callback err  if err
          @update operation, (err) =>
            return callback err  if err
            @addRedeemer account, callback


  # send invites from group dashboard
  @create = secure (client, group, email, options, callback)->
    [callback, options] = [options, callback]  unless callback
    {delegate} = client.connection
    type       = 'admin'

    selector = {email, group, type}
    JInvitation.one selector, (err, existingInvite)=>
      return callback err                   if err
      return callback null, existingInvite  if existingInvite

      JUser = require './user'
      JUser.one {email}, (err, user)=>
        return callback err  if err

        code = @generateInvitationCode 'admin', email, group
        invite = new JInvitation {
          code, email, group
          origin: ObjectRef(delegate)
        }
        invite.username = user.username  if user
        invite.save (err)->
          return callback err  if err
          invite.addInvitedBy delegate, (err)->
            callback err, invite

  sendMail: permit 'send invitations',
    success: (client, group, options, callback)->
      [callback, options] = [options, callback]  unless callback
      options ?= {}

      JUser            = require './user'
      {delegate}       = client.connection
      {host, protocol} = @constructor.getHostAndProtocol

      url  = "#{protocol}//#{host}"
      url += "/#{group.slug}"  unless group.slug is 'koding'
      url += "/Invitation/#{encodeURIComponent @code}"

      details = {
        group    : group.title
        inviter  : delegate.getFullName()
        url
        isPublic : if group.privacy == 'public' then yes else no
        message  : options.message
      }

      JUser.fetchUser client, (err, inviter)=>
        email = new JMail {
          @email
          subject : @constructor.getSubject details
          content : @constructor.getMessage details
          replyto : inviter.email
          bcc     : options.bcc
        }
        email.save (err)=>
          @update {$set: status: if err then 'couldnt send email' else 'sent'}, callback

  @getSubject = ({inviter, group, isPublic})->
    subject    = "#{inviter} has invited you to #{group}"
    subject   += ' on Koding'  if isPublic
    subject   += '!'

  @getMessage  = ({inviter, group, isPublic, url, message})->
    if message
      message  = message.replace /#INVITER#/g, inviter
      content  = message.replace /#URL#/g,     url
    else
      subject  = "#{inviter} has invited you to the group #{group}"
      subject += ' on Koding'  if isPublic
      subject += '.'
      content  = """
        Hi there,

        #{subject}

        This link will allow you to join the group: #{url}

        If you reply to this email, it will go to #{inviter}.

        Enjoy! :)
        """

      content += @getFooter()  if isPublic
    return content


  # multiuse invitations

  @createMultiuse = permit 'send invitations',
    success: ({connection:{delegate}, context:{group}}, options, callback) ->
      {code, maxUses, memo} = options
      maxUses ?= 1

      invite = new JInvitation {
        code
        group
        memo
        maxUses
        type      : 'multiuse'
        origin    : ObjectRef(delegate)
      }
      invite.save (err)->
        return callback err  if err
        invite.addInvitedBy delegate, (err)->
          return callback err  if err
          JGroup = require './group'
          JGroup.one slug: group, (err, groupObj)->
            return callback err  if err
            groupObj.addInvitation invite, callback

  #### Leaving it here incase we decide to have another beta: SA
  #@createMultiForResurrection = permit 'send invitations',
    #success: (client, usernames, callback)->
      #if typeof usernames is String
        #return callback {"Usernames should be an array"}

      #daisy queue = usernames.map (username) =>
        #=> @_createForResurrection client, username, callback

      #queue.push -> callback null

  #@createForResurrection = permit 'send invitations',
    #success: (client, username, callback)->
      #@_createForResurrection client, username, callback

  #@_createForResurrection : ({connection:{delegate}}, username, callback)->
    #JUser = require './user'
    #JUser.one {username}, (err, user)=>
      #return callback err  if err or !user

      #{email} = user
      #code    = @generateInvitationCode "group", email, "resurrection"
      #invite  = new JInvitation {
        #code
        #email
        #type       : "multiuse"
        #group      : "resurrection"
        #origin     : ObjectRef(delegate)
        #maxUses    : 100
        #createdFor : username
      #}
      #invite.save callback

  #@sendResurrectionEmails = permit 'send invitations',
    #success: (client, username, callback)->
      #JInvitation.some {group:"resurrection", status:"active"}, {}, (err, invites)=>
        #daisy queue = invites.map (invite) =>
          #=>
            #email = new JMail {
              #email   : invite.email
              #subject : "You're invited to try a new version Koding!"
              #content : @getRessurrectionMessage invite.code
              #replyto : "hello@koding.com"
            #}
            #email.save (err)->
              #invite.update {$set: status: if err then 'couldnt send email' else 'sent'}, ->

        #queue.push -> callback null

  #@getRessurrectionMessage = (token)->
    #"""
    #We need loyal users like you to test it out: http://new.koding.com/Login/#{token}
    #This is a private beta, please don't share your url.

    #Hope you like it!

    #Koding Team
    #"""
  #### Leaving it here incase we decide to have another beta: SA

  @suggestCode = permit 'send invitations',
    success: (client, callback, tries=0)->
      return callback 'could not generate code, too many tries!'  if tries > 10
      code = createId 40
      @one {code}, (err, invitation)=>
        return @suggestCode client, callback, tries + 1  if err or invitation
        callback null, code

  modifyMultiuse: permit 'send invitations',
    success: ({context:{group}}, {maxUses, memo}, callback)->
      setModifier = {}
      setModifier.maxUses = if maxUses < @uses then @uses else maxUses
      setModifier.memo    = memo
      setModifier.group   = 'koding'  if group is 'koding' and not @group?

      @update $set: setModifier, callback


  # invite friends

  @inviteFriend = secure (client, {email, customMessage}, callback)->
    {delegate} = client.connection
    type       = 'friend'

    selector = {email, type}
    JInvitation.one selector, (err, inv)=>
      return inv.sendInviteFriendMail client, customMessage, callback  if inv

      code = @generateInvitationCode 'friend', email
      invite = new JInvitation {
        code
        customMessage
        email
        type
        origin : ObjectRef(delegate)
        group  : 'koding'
      }
      invite.save (err)->
        return callback err  if err
        invite.addInvitedBy delegate, (err)->
          return callback err  if err
          invite.sendInviteFriendMail client, customMessage, callback

  sendInviteFriendMail: (client, customMessage, callback)->
    {delegate} = client.connection
    {host, protocol} = @constructor.getHostAndProtocol

    messageOptions =
      body      : customMessage
      inviter   : delegate.getFullName()
      url       : "#{protocol}//#{host}/Invitation/#{encodeURIComponent @code}"

    JUser = require './user'
    JUser.fetchUser client, (err,inviter)=>
      email = new JMail {
        @email
        subject  : @constructor.getInviteFriendSubject messageOptions
        content  : @constructor.getInviteFriendMessage messageOptions
        replyto  : inviter.email
      }
      email.save (err)=>
        @update {$set: status: if err then 'couldnt send email' else 'sent'}, callback

  @getInviteFriendSubject = ({inviter})-> "#{inviter} has invited you to Koding!"

  @getInviteFriendMessage = ({inviter, url, message})->
    message or= "#{inviter} has invited you to Koding!"
    """
    Hi there, we hope this is good news :) because,

    #{message}

    This link will allow you to create an account:
    #{url}

    If you reply to this email, it will go back to your friend who invited you.

    #{@getFooter()}
    """

  @getFooter = ->
    """
    If you're curious, here is a bit about Koding, http://techcrunch.com/2012/07/24/koding-launch/

    In very short, Koding lets you code, share and have fun.

    And welcome to Koding!
    Devrim - on behalf of whole Koding team


    notes:
    - of course you can mail me back if you like... (just hit reply)
    - this is still beta, expect bugs, please don't be surprised if you spot one.
    - if you already have an account, you can forward this to a friend.
    - no matter how you signed up, you will not receive any newsletters or other crap.
    - if you never signed up (sometimes people type their emails wrong, and it happens to be yours), please let us know.
    - take a look at http://wiki.koding.com for things you can do.
    - if you fall in love with this project, please let us know http://blog.koding.com/2012/06/we-want-to-date-not-hire/
    """
