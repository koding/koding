jraphical = require 'jraphical'
crypto    = require 'crypto'
Bongo     = require "bongo"
Email     = require './email'

{secure, signature, dash} = Bongo

module.exports = class JInvitation extends jraphical.Module

  @trait __dirname, '../traits/grouprelated'
  @trait __dirname, '../traits/protected'


  {permit} = require './group/permissionset'

  @isEnabledGlobally = yes



  @share()

  @set
    permissions     :
      'send invitations'                  : ['moderator', 'admin']
    indexes         :
      code          : 'unique'
    sharedMethods   :

      instance:
        remove:
          (signature Function)

      static:
        create:
          (signature String, String, Object, Function)
        byCode:
          (signature String, Function)

    sharedEvents    :
      static        : []
      instance      : []
    schema          :
      code          :
        type        : String
        required    : yes
      email         : String
        type        : String
        required    : yes
      groupName     :
        type        : String
        required    : yes
      status        :
        type        : String
        enum        : ['invalid status type', [
          'sent','active','blocked',
          'redeemed','couldnt send email',
          'accepted','ignored'
        ]]
        default     : 'active'
      createdAt     :
        type        : Date
        default     : -> new Date

  remove$: permit 'send invitations',
    success: (client, callback=->)-> @remove callback

  @byCode = (code, callback)-> @one {code}, callback

  @generateInvitationCode = (email, group)->
    code = crypto.createHmac 'sha1', 'kodingsecret'
    code.update email
    code.update group
    code.digest 'hex'

  redeem$: secure ({connection:{delegate}}, callback=->)->
    @redeem delegate, callback

  redeem: (account, callback) ->
    operation = $set : { status: 'redeemed' }
    @update operation, callback

  @create = secure (client, options, callback)->
    { groupName } = client.connection

    groupName  or= 'koding'

    { emails }  = options

    queue = emails.map (email)=>=>
      code = @generateInvitationCode email, groupName

      invite = new JInvitation {
        code
        email
        groupName
      }

      invite.save (err)->
        return callback err   if err
        queue.fin()

    dash queue, callback

  # sendMail: permit 'send invitations',
  #   success: (client, group, options, callback)->
  #     [callback, options] = [options, callback]  unless callback
  #     options ?= {}

  #     JUser            = require './user'
  #     {delegate}       = client.connection

  #     JUser.fetchUser client, (err, inviter)=>
  #       Email.queue delegate.profile.nickname, {
  #         to         : @email
  #         subject    : "subject"
  #         content    : "content"
  #       }, {inviterEmail : inviter.email}, callback
