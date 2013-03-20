
jraphical = require 'jraphical'
CActivity = require './activity'
JAccount  = require './account'
KodingError = require '../error'

module.exports = class JKite extends jraphical.Module

  {Relationship} = jraphical

  {ObjectId, ObjectRef, Inflector, secure, daisy, race} = require 'bongo'

  @share()

  @set
    indexes         :
      apiKey          : 'unique'
    sharedMethods   :
      instance      : [
          'delete'
        ]
      static        : [
          'create'
        ]
    schema          :
      name          :
        type        : String
        required    : yes
      secret         :
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
        apiKey    = "kite-api-key-" + key.toString 'hex'
        apiSecret = "kite-api-secret-" + secret.toString 'hex'
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