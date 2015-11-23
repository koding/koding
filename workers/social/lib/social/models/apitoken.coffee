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

  @share()

  @set
    sharedEvents     :
      static         : []
      instance       : []
    permissions      :
      'create token' : ['admin']
      'remove token' : ['admin']
    indexes          :
      code           : 'unique'
    sharedMethods    :
      static:
        create: [
          (signature Function)
          (signature Object, Function)
        ]
      instance:
        remove:
          (signature Function)
    schema           :
      code           :
        type         : String
        required     : yes
        default      : hat
      group          :
        type         : String
        required     : yes
      originId       :
        type         : ObjectId
        required     : yes
      createdAt      :
        type         : Date
        default      : -> new Date
      modifiedAt     :
        type         : Date
        default      : -> new Date


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
          queue.next()

      ->
        # creating token
        token = new JApiToken
          code     : hat()
          group    : group
          originId : account.getId()

        token.save (err) ->
          return callback err  if err
          callback null, token

    ]

    daisy queue


  @create$: permit 'create token',

    success: (client, callback) ->

      group    = client?.context?.group
      account  = client?.connection?.delegate

      unless account and group
        return callback new KodingError 'account and group must be set!'

      data = { group, account }
      JApiToken.create data, callback


  remove$: permit 'remove token',

    success: (client, callback) ->
      @remove callback






