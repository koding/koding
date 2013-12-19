jraphical = require 'jraphical'
CActivity = require './activity'
JAccount  = require './account'
KodingError = require '../error'

module.exports = class JKodingKey extends jraphical.Module

  {Relationship} = jraphical

  {Base, secure, race, signature} = require 'bongo'

  @share()

  @set
    softDelete        : yes
    sharedMethods     :
      instance        :
        revoke        :
          (signature Function)

      static          :
        create        :
          (signature Object, Function)
        fetchAll      :
          (signature Object, Function)
        fetchByKey    :
          (signature Object, Function)
        registerHostnameAndKey :
          (signature Object, Function)
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

  @authCheckKey = (key, callback)->
    return false if not key
    return false if typeof key isnt "string"

    key = decodeURIComponent key
    return false if key.length isnt 64
    return true

  @registerHostnameAndKey$ = secure (client, options, callback)->
    {connection:{delegate}} = client
    errMessage = "You need to be registered/loggedin in order to register your Kite"
    return callback new KodingError errMessage if delegate.type isnt "registered"
    # set username
    options.username = delegate.profile.nickname
    @registerHostnameAndKey options, callback

  @registerHostnameAndKey = ({username, key, hostname}, callback)->
    return new KodingError "Key is not valid" unless @authCheckKey key
    return new KodingError "Data is not valid" unless username and hostname

    @fetchByUserKey {username, key}, (err, kodingKey)=>
      return callback new KodingError "Koding Auth Error - 3" if err
      if kodingKey
        errMessage = "Authentication already established with #{kodingKey.hostname}!"
        return callback new KodingError errMessage

      # if not created before, create here
      @createKeyByUser {username, hostname, key}, (err, data)=>
        return callback new KodingError "Koding Auth Error - 3" if err
        return callback null, "Authentication is successfull! Using id: #{data.hostname}"
