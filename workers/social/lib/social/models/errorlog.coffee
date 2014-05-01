ElasticSearch = require "./elasticsearch"

{
  secure
  signature
} = require 'bongo'

module.exports = class JErrorLog extends ElasticSearch
  @share()

  @set
    sharedMethods :
      static:
        create: (signature Object, Function)

  @errorsIndex: (type)->
    @getIndexOptions("errorlogs", type)

  @create: secure (client, params, callback)->
    @getUserInfo client, (err, record)=>
      return callback err  if err

      {error, numberOfVms, kontainer} = params

      error = error.split(" ").join("_")

      record.error       = error
      record.numberOfVms = numberOfVms
      record.kontainer   = kontainer

      documents = [ record ]

      ElasticSearch.create @errorsIndex(error), documents, callback
