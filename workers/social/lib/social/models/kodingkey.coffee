
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
      static          : ['create', 'fetchAll']
    indexes           :
      key             : ['unique']
    schema            :
      key             : String
      hostname        : String

    relationships         :->
      creator             :
        targetType        : JAccount
        as                : 'owner'

  @create = secure (client, data, callback)->
    {delegate} = client.connection
    
    key = new JKodingKey data
    key.save (err)->
      if err
        callback err
      else
        key.addCreator delegate, (err)->
          if err
            callback err
          else
            callback null, key

  @fetchAll = secure ({connection:{delegate}}, options, callback)->
    selector = {
      targetId   : delegate._id
      sourceName : 'JKodingKey'
      as         : 'owner'
    }
    options or= {}
    @fetcher selector, options, callback

  @fetchByKey = secure ({connection:{delegate}}, options, callback)->
    selector = {
      targetId   : delegate._id
      sourceId   : options.key
      sourceName : 'JKodingKey'
      as         : 'owner'
    }
    options or= {}
    @fetcher selector, options, callback

  @fetcher = (selector, options, callback)->
    Relationship.some selector, options, (err, relationships)=>
      if err then callback err
      else if relationships.length is 0 then callback null, []
      else
        teasers = []
        collectTeasers = race (i, root, fin)->
          root.fetchSource (err, data)->
            if err
              callback err
              fin()
            else if not data
              # if relation found but source is not found
              fin()
            else
              teasers.push data
              fin()
        , -> callback null, teasers
        collectTeasers relationship for relationship in relationships
