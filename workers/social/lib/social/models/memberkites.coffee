jraphical = require 'jraphical'
JAccount  = require './account'
KodingError = require '../error'
JKite     = require './kites'
module.exports = class JMemberKite extends jraphical.Module

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
          'create', 'get', 'fetchAll', 'control'
        ]
    schema          :
      description   :
        type        : String
        required    : no
      status        :
        type        : String
        required    : no
        default     : "active"
      count         :
        type        : Number
        required    : no
        default     : 1
      key           :
        type        : String
        required    : no
    relationships   :->
      creator       :
        targetType  : JAccount
        as          : 'owner'
      parent        :
        targetType  : JKite
        as          : 'parent'

  @create = secure (client, data, callback)->
    {delegate} = client.connection

    description  : data.description
    callCount    : data.callCount
    kiteId = data.kites
    delete data.kites

    crypto = require 'crypto'

    crypto.randomBytes 32, (ex1, key) ->
      data.key = key.toString 'hex'

      memberKite = new JMemberKite data
      memberKite.save (err)=>
        if err
          callback err
        else
          memberKite.addCreator delegate, (err)=>
            if err
              callback err
            else
              JKite.one {_id: kiteId}, (err, kite) =>
                memberKite.addParent kite, (err)=>
                  if err
                    callback err
                  else
                    callback null, memberKite


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

    @one {
      key      : data.key
    }, (err, data)=>
      if err
        callback err
      else
        callback null, data

  @fetchAll = secure ({connection:{delegate}}, options, callback)->

    selector = {
      targetId   : delegate._id
      sourceName : 'JMemberKite'
      as         : 'owner'
    }

    options or= {}

    @fetcher selector, options, callback



  @fetcher = (selector, options, callback)->

    Relationship.some selector, options, (err, relationships)=>
      if err then callback err
      else if relationships.length is 0 then callback null
      else
        teasers = []
        collectTeasers = race (i, root, fin)->
          root.fetchSource (err, memberKite)->
            if err
              callback err
              fin()
            else if not memberKite
              # if relation found but source is not found
              fin()
            else
              teasers.push(memberKite)
              fin()
        , -> callback null, teasers
        collectTeasers relationship for relationship in relationships

  delete: secure ( {connection: {delegate} }, callback)->
    @remove callback
