ElasticSearch = require "./elasticsearch"
_             = require "underscore"

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

  @errorsIndex:->
    @getIndexOptions("errorlogs", "errors")

  @create: secure (client, params, callback)->
    @getUserInfo client, (err, record)=>
      return callback err  if err

      record    = _.extend record, params
      documents = [ record ]

      ElasticSearch.create @errorsIndex(), documents, callback
