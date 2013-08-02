_ = require 'underscore'
neo4j = require "neo4j"

{Base, ObjectId, race} = require 'bongo'

module.exports = class Graph
  constructor:({config, facets})->
    @db = new neo4j.GraphDatabase(config.read + ":" + config.port);
    @facets = facets

  fetchRelationshipCount:(options, callback)->
    {groupId, relName} = options
    query = """
      START group=node:koding("id:#{groupId}")
      match group-[:#{relName}]->items
      return count(items) as count
    """
    @db.query query, {}, (err, results) ->
      if err then callback err, null
      else callback null, results[0].count
