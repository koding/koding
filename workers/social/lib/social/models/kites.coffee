
jraphical = require 'jraphical'
CActivity = require './activity'
JAccount  = require './account'
KodingError = require '../error'

module.exports = class JKite extends jraphical.Module

  {Relationship} = jraphical

  {Base, secure, race} = require 'bongo'

  @share()

  @set
    softDelete : yes
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
          'create', 'get', 'fetchAll', 'control', 'fetchKites', 'checkKiteName'
        ]
    schema                :
      description         :
        type              : String
        required          : no
      kiteName            :
        type              : String
        required          : yes
      privacy             :
        type              : String
        required          : yes
        default           : "public"
      type                :
        type              : String
        required          : yes
        default           : "free"
      status              :
        type              : String
        required          : no
        default           : "active"
      count               :
        type              : Number
        required          : no
        default           : 0
      purchaseAmount      :
        type              : Number
        required          : no
        default           : 0
      key                 :
        type              : String
        required          : no

    relationships         :->
      creator             :
        targetType        : JAccount
        as                : 'owner'

  @create = secure (client, data, callback)->
    {delegate} = client.connection

    crypto = require 'crypto'

    crypto.randomBytes 32, (ex1, key) ->
      apiKey   = key.toString 'hex'
      data.key = apiKey

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
          callback null, result

  @control = (data, callback)->
    {limit, skip, sort}  = data

    @one {
      key      : data.key
      kiteName : data.kiteName
    }, (err, data)=>
      if err
        callback err
      else
        callback null, data

  @checkKiteName = (data, callback)->

    @one {
      kiteName : data.kiteName
    }, (err, data)=>
      if err
        callback err
      else
        console.log data
        result = true
        result = false if data

        callback null, result


  @fetchAll = secure ({connection:{delegate}}, options, callback)->

    selector = {
      targetId   : delegate._id
      sourceName : 'JKite'
      as         : 'owner'
    }

    options or= {}

    @fetcher selector, options, callback


  @fetchKites = (selector, options, callback)->

    selector or= {}
    options  or= {}

    @fetcher selector, options, callback


  @fetcher = (selector, options, callback)->

    Relationship.some selector, options, (err, relationships)=>
      if err then callback err
      else if relationships.length is 0 then callback null, []
      else
        teasers = []
        collectTeasers = race (i, root, fin)->
          root.fetchSource (err, kite)->
            if err
              callback err
              fin()
            else if not kite
              # if relation found but source is not found
              fin()
            else
              teasers.push(kite)
              fin()
        , -> callback null, teasers
        collectTeasers relationship for relationship in relationships


  delete: secure ({connection:{delegate}}, callback)->

    @remove callback
