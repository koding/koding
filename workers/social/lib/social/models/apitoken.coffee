hat           = require 'hat'
JGroup        = require './group'
JAccount      = require './account'
jraphical     = require 'jraphical'
KodingError   = require '../error'
{ permit }    = require './group/permissionset'
{ daisy
  secure
  ObjectId
  signature } = require 'bongo'


module.exports = class JApiToken extends jraphical.Module

  Validators = require './group/validators'

  PERMISSION_EDIT_GROUPS = [
    { permission: 'edit groups',     superadmin: yes }
    { permission: 'edit own groups', validateWith: Validators.group.admin }
  ]


  @share()

  @set
    sharedEvents       :
      static           : []
      instance         : []
    indexes            :
      code             : 'unique'
    sharedMethods      :
      static:
        create: [
          (signature Function)
          (signature Object, Function)
        ]
      instance:
        remove:
          (signature Function)
    schema             :
      code             :
        type           : String
        required       : yes
        default        : hat
      group            :
        type           : String
        required       : yes
      originId         :
        type           : ObjectId
        required       : yes
      createdAt        :
        type           : Date
        default        : -> new Date
      modifiedAt       :
        type           : Date
        default        : -> new Date


  @create: (data, callback) ->

    { account, group } = data

    unless account and group
      return callback new KodingError 'account and group slug must be set!'

    queue = [

      ->
        # validating data params
        unless account instanceof JAccount
          return callback new KodingError 'account is not an instance of Jaccount!'

        JGroup.one { slug : group }, (err, group_) ->
          return callback err                                 if err
          return callback new KodingError 'group not found!'  unless group_

          unless !!group_.getAt 'isApiEnabled'
            return callback new KodingError 'api usage is not enabled for this group'

          queue.next()

      ->
        # creating token
        token = new JApiToken
          code     : hat()
          group    : group
          originId : account.getId()

        token.save (err) ->
          return callback err  if err
          token.username = account.profile.nickname
          callback null, token

    ]

    daisy queue


  @create$: permit
    advanced: PERMISSION_EDIT_GROUPS
    success: (client, callback) ->

      group    = client?.context?.group
      account  = client?.connection?.delegate

      unless account and group
        return callback new KodingError 'account and group must be set!'

      data = { group, account }
      JApiToken.create data, callback


  remove$: permit
    advanced: PERMISSION_EDIT_GROUPS
    success: (client, callback) ->
      @remove callback






