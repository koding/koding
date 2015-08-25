# coffeelint: disable=no_implicit_braces
# JTeamInvitation is a temporary invitation token collection will be used for
# inviting companies to use/try teams product, this file should be removed after
# releasing teams product.
{ argv }    = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")
jraphical   = require 'jraphical'
shortid     = require 'shortid'
Bongo       = require 'bongo'
Tracker     = require './tracker'
KodingError = require '../error'
{ extend }  = require 'underscore'

{ protocol, hostname } = KONFIG
{ secure, signature, dash } = Bongo

emailsanitize = require './user/emailsanitize'

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

  @create: permit 'send invitations',
    success: (client, options, callback) ->

      data =   {
        code      : options.code or shortid.generate()[0..3] # eg: VJPj9
        email     : options.email
        groupName : options.groupName or 'koding'
      }

      invite = new JTeamInvitation data
      invite.save (err) ->
        return callback new KodingError err  if err
        return callback null, invite

  @byCode: (code, callback) ->
    @one { code }, callback

