ElasticSearch = require './elasticsearch'

{
  secure
  signature
} = require 'bongo'

module.exports = class JPageHit extends ElasticSearch
  @share()

  @set
    sharedMethods :
      static:
        create: (signature Object, Function)

  @pagesHitIndex :->
    @getIndexOptions("pagehits", "events")

  @create: secure (client, params, callback)->
    @getUserInfo client, (err, record)=>
      return callback err  if err

      {path, query} = params
      if path is "/"
        path = "/Home"

      {pathname, query} = (require "url").parse path
      query             = (require "querystring").parse query

      record.path  = pathname
      record.query = query

      documents = [ record ]

      ElasticSearch.create @pagesHitIndex(), documents, callback
