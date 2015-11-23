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

    { accountId, group } = data

    unless accountId and group
      return callback new KodingError 'accountId and group must be set!'

    queue = [

      ->
        JAccount.one { _id : accountId }, (err, account) ->
          return callback err                                   if err
          return callback new KodingError 'account not found!'  unless account
          queue.next()

      ->
        JGroup.one { slug : group }, (err, group_) ->
          return callback err                                 if err
          return callback new KodingError 'group not found!'  unless group_
          queue.next()

      ->
        token = new JApiToken
          code     : hat()
          group    : group
          originId : accountId

        token.save (err) ->
          return callback err  if err
          callback err, token

    ]

    daisy queue


  @create$: permit 'create token',

    success: (client, callback) ->

      group    = client?.context?.group
      account  = client?.connection?.delegate

      unless account and group
        return callback new KodingError 'account and group must be set!'

      data = { group, accountId : account.getId() }
      JApiToken.create data, callback


  remove$: permit 'remove token',

    success: (client, callback) ->
      @remove callback






