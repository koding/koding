
jraphical = require 'jraphical'
CActivity = require './activity'
JAccount  = require './account'
KodingError = require '../error'

module.exports = class JKite extends jraphical.Module

  {Relationship} = jraphical

  {Base, dash, ObjectId, ObjectRef, Inflector, secure, daisy, race} = require 'bongo'

  @share()

  @set
    permissions: [
      'read kites'
      'create kites'
      'edit kites'
      'delete kites'
      'delete own kites'
    ]  
    sharedMethods   :
      instance      : [
          'delete'
        ]
      static        : [
          'create', 'get', 'fetchAll', 'control'
        ]
    schema          :
      appName       :
        type        : String
        required    : yes
      kiteName      :
        type        : String
        required    : yes
      secret        :
        type        : String
        required    : no
      key          :
        type        : String
        required    : no
    relationships   :->
      JAccount = require './account'
      creator       :
        targetType  : JAccount
        as          : 'owner'

  @create = secure (client, data, callback)->
    {delegate} = client.connection

    crypto = require 'crypto'

    crypto.randomBytes 12, (ex1, key) ->
      crypto.randomBytes 12, (ex2, secret) ->
        #todo remove prefixes
        apiKey    = "key-" + key.toString 'hex'
        apiSecret = "secret-" + secret.toString 'hex'
        data.key = apiKey
        data.secret = apiSecret

        kite = new JKite data
        kite.save (err)->
          if err
            callback err
          else
            kite.addCreator delegate, (err)->
              if err
                callback err
              else
                callback null, kite


  @get = secure ({connection:{delegate}}, data, callback)->
    {limit, skip, sort}  = data

    Relationship.one {
      as          : 'owner'
      targetId    : delegate._id
      sourceId    : data.id
    }, (err, relation)=>
      if err
        callback err
      else
        relation.fetchSource (err, result)=>
          console.log result 
          callback null, result

  @control = (data, callback)->
    {limit, skip, sort}  = data

    @one {
      key    : data.key
      secret : data.secret
    }, (err, data)=>
      if err
        callback err
      else
        callback null, data


  @fetchAll = secure ({connection:{delegate}}, options, callback)->

    selector = {
      targetId   : delegate._id
      sourceName : 'JKite'
      as         : 'owner'
    }

    options or= {}

    Relationship.some selector, options, callback


  delete: secure ({connection:{delegate}}, callback)->
    # console.log this
    # unless delegate.can 'delete', this
    #   throw new KodingError 'Access denied!'

    @remove callback
    
    # Relationship.getDeleteHelper {
    #   targetId    : delegate._id
    #   sourceId    : @getId()
    # }, 'source', callback
