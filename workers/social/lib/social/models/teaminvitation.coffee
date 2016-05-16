# JTeamInvitation is a temporary invitation token collection will be used for
# inviting companies to use/try teams product, this file should be removed after
# releasing teams product.
KONFIG      = require 'koding-config-manager'
jraphical   = require 'jraphical'
shortid     = require 'shortid'
Bongo       = require 'bongo'
async       = require 'async'
Tracker     = require './tracker'
KodingError = require '../error'
{ extend }  = require 'underscore'
async       = require 'async'

{ protocol, hostname } = KONFIG
{ secure, signature }  = Bongo

emailsanitize = require './user/emailsanitize'

getName = (delegate) ->

  { nickname, firstName, lastName } = delegate.profile

  name = nickname
  name = firstName              if firstName
  name = "#{name} #{lastName}"  if firstName and lastName

  return name



module.exports = class JTeamInvitation extends jraphical.Module

  @trait __dirname, '../traits/protected'

  { permit } = require './group/permissionset'

  @share()

  @set
    indexes         :
      code          : 'unique'
    sharedMethods   :
      instance:
        remove:[
          (signature Function)
          (signature Object, Function)
        ]
      static:
        create:
          (signature Object, Function)
        byCode:
          (signature String, Function)
        sendInvitationEmails:
          (signature [String], Function)

    sharedEvents    :
      static        : []
      instance      : []
    schema          :
      code          :
        type        : String
        required    : yes
      email         :
        type        : String
        required    : yes
        set         : emailsanitize
      groupName     :
        type        : String
      status        :
        type        : String
        enum        : ['invalid status type', [
          'pending',
          'used'
        ]]
        default     : 'pending'
      createdAt     :
        type        : Date
        default     : -> new Date

  markAsUsed: (callback) ->
    operation = { $set : { status: 'used' } }
    @update operation, callback

  validTypes: ['pending']

  isValid: -> @status in @validTypes

  remove$: permit 'send invitations',
    success: (client, callback) ->
      @remove callback


  @create: (options, callback) ->

    data =
      code      : options.code or shortid.generate()[0..3] # eg: VJPj9
      email     : options.email
      groupName : options.groupName or 'koding'

    invite = new JTeamInvitation data
    invite.save (err) ->
      return callback new KodingError err  if err
      return callback null, invite


  @create$: permit 'send invitations',
    success: (client, options, callback) ->
      @create options, callback


  @byCode: (code, callback) ->
    @one { code }, callback

  @sendInvitationEmails: permit 'send invitations',
    success: (client, emails, callback) ->

      inviter     = getName client.connection.delegate
      queue       = []
      invitations = []

      emails.forEach (email) =>
        queue.push (fin) =>
          @create { email }, (err, invitation) ->
            return fin err  if err

            properties =
              inviter  : inviter
              invitee  : invitation.email
              link     : "#{protocol}//#{hostname}/Teams/#{encodeURIComponent invitation.code}"

            Tracker.identifyAndTrack invitation.email, { subject: Tracker.types.INVITED_CREATE_TEAM }, properties, (err) ->
              fin err, invitation


      async.parallel queue, callback
