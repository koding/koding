jraphical = require 'jraphical'
CActivity = require './activity'
JAccount  = require './account'
KodingError = require '../error'

module.exports = class JKodingKey extends jraphical.Module

  {Relationship} = jraphical

  {Base, secure, race} = require 'bongo'

  @share()

  @set
    softDelete        : yes
    sharedMethods     :
      instance        : ['revoke']
      static          : ['create', 'fetchAll', 'fetchByKey']
    indexes           :
      key             : ['unique']
    schema            :
      key             : String
      hostname        : String
      owner           : String

  @create = secure (client, data, callback)->
    {delegate} = client.connection
    key = new JKodingKey
      key     : data.key
      hostname: data.hostname
      owner   : delegate._id
    key.save (err)->
      if err
        callback err
      else
        callback null, key

  @fetchAll = secure ({connection:{delegate}}, options, callback)->
    JKodingKey.all
      owner : delegate.getId()
    , (err, keys)->
      callback err, keys

  @fetchByKey = secure ({connection:{delegate}}, options, callback)->
    JKodingKey.all
      owner : delegate.getId()
      key   : options.key
    , (err, keys)->
      callback err, keys

  # TODO: Do not use username. Use secure instead.
  @fetchByUserKey = (options, callback)->
    JAccount.one
      'profile.nickname': options.username
    , (err, account)->
      if err then callback err
      else if not account
        callback null, null
      else
        JKodingKey.one
          key   : options.key
          owner : account._id
        , (err, key)->
          callback err, key

  @fetchKey = (options, callback)->
    JKodingKey.one
      key   : options.key
    , (err, key)->
      callback err, key

  @fetchByKeyAndHostname = (options, callback)->
    JKodingKey.one
      owner : delegate.getId()
      key   : options.key
      hostname: options.hostname
    , (err, keys)->
      callback err, keys

  @createKeyByUser = (options, callback)->
    JAccount.one
      'profile.nickname': options.username
    , (err, account)->
      if err then callback err
      else if not account
        callback null, null
      else
        key = new JKodingKey
          key     : options.key
          hostname: options.hostname
          owner   : account._id
        key.save (err)->
          if err
            callback err
          else
            callback null, key

  revoke: secure ({connection:{delegate}}, callback)->
    JKodingKey.one
      owner : delegate.getId()
      _id    : @getId()
    , (err, key)->
      key.remove callback
