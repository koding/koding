
jraphical = require 'jraphical'
CActivity = require './activity'
JAccount  = require './account'
KodingError = require '../error'

module.exports = class JKite extends jraphical.Module

  {Relationship} = jraphical

  {Base, secure, race} = require 'bongo'

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
        kite.save (err)=>
          if err
            callback err
          else
            kite.addCreator delegate, (err)=>
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

    Relationship.some selector, options, (err, relationships)=>
      if err then callback err, []
      else if relationships.length is 0 then callback null, []
      else
        teasers = []
        collectTeasers = race (i, root, fin)->
          root.fetchSource (err, kite)->
            if err
              callback err
              fin()
            else if not kite
              console.warn "Source does not exists:", root.sourceName, root.sourceId
              fin()
            else
              teasers.push(kite)
              fin()
        , -> callback null, teasers
        collectTeasers relationship for relationship in relationships

  delete: secure ({connection:{delegate}}, callback)->

    @remove callback
