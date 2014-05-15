ElasticSearch = require './elasticsearch'
_             = require "underscore"

{
  secure
  signature
} = require 'bongo'

module.exports = class JMetric extends ElasticSearch
  @share()

  @set
    sharedMethods :
      static:
        create: (signature Object, Function)

  @metricsIndex :->
    @getIndexOptions("metrics", "events")

  @create: secure (client, params, callback)->
    @getUserInfo client, (err, record)=>
      return callback err  if err

      record = _.extend params, record
      documents = [ record ]

      ElasticSearch.create @metricsIndex(), documents, callback
