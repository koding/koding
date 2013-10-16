{Graph} = require './index'
QueryRegistry = require './queryregistry'

module.exports = class Aggregation extends Graph

  @fetchRelationshipCount:(options, callback)->
    query = QueryRegistry.aggregation.relationshipCount options.relName
    @fetch query, options, (err, results) ->
      if err then callback err, null
      else callback null, results[0].count
