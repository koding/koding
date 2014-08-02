jraphical = require 'jraphical'
JAccount  = require './account'
KodingError = require '../error'

module.exports = class JKodingKey extends jraphical.Module

  {Relationship} = jraphical

  {Base, secure, race, signature} = require 'bongo'

  @share()

  @set
    sharedEvents      :
      static          : []
      instance        : []
    softDelete        : no
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

  @checkKey = (options, callback)->
    {key} = options
    return new KodingError "Key is not valid" unless key and @authCheckKey key
    JKodingKey.one
      key   : options.key
    , (err, key)->
      return callback err, no if err
      return callback null, no unless key
      callback null, yes

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

  @authCheckKey = (key)->
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

    JKodingKey.one {key}, (err, kodingKey)->
      if err
        console.warn "Error occured while fetching koding-key username: #{username}, key: #{key}, err :#{err}"
        return callback new KodingError "There is a problem with your key"

      if kodingKey
        errMessage = "Authentication already established with #{kodingKey.hostname}!"
        error = new KodingError errMessage
        error.code = 201
        return callback error

      # if not created before, create here
      JKodingKey.createKeyByUser {username, hostname, key}, (err, data)->
        if err
          console.warn "Error occured while creating koding key - Err: #{err}, "
          return callback new KodingError "An error occured while saving your key, please try again later"
        return callback null, "Authentication is successfull! Using id: #{data.hostname}"
