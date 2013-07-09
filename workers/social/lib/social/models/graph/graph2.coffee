neo4j = require "neo4j"
{Base} = require 'bongo'

module.exports = class Graph
  @getDb:=>
    return @db if @db

    {read, port} = KONFIG.neo4j
    @db = new neo4j.GraphDatabase(read + ":" + port);
    return @db

  @fetch:(query, params, callback)->
    @getDb().query query, params, callback

  @revive:(results, callback)->
    if results.length < 1
      return callback
    data  = []
    for result in results
      continue unless result[0]
      result = result[0]
      result.bongo_ =
        constructorName : result.name
        instanceId : result.id
      obj = new Base.constructors[result.name] result
      data.push obj
    callback data

  # we have a bug here for objects that have array properties
  # they are converted into properties, not to array
  @objectify:(incomingObjects, callback)->
    incomingObjects = [].concat(incomingObjects)
    generatedObjects = []
    for incomingObject in incomingObjects
      generatedObject = {}
      for k of incomingObject
        temp = generatedObject
        parts = k.split "."
        key = parts.pop()
        while parts.length
          part = parts.shift()
          temp = temp[part] = temp[part] or {}
        temp[key] = incomingObject[k]
      generatedObjects.push generatedObject
    callback generatedObjects
