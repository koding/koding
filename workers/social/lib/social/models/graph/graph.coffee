_ = require 'underscore'
neo4j = require "neo4j-koding"
{race} = require 'sinkrow'
{Base, ObjectId, race} = require 'bongo'

module.exports = class Graph
  @getDb:=>
    return @db if @db

    {read, port} = KONFIG.neo4j
    @db = new neo4j.GraphDatabase(read + ":" + port);
    return @db

  # TODO: move it to a proper place eg. trait maybe..
  @getExemptUsersClauseIfNeeded: (requestOptions, callback)->
    if not requestOptions.withExempt
      {delegate} = requestOptions.client.connection
      JAccount = require '../account'
      JAccount.getExemptUserIds (err, ids)=>
        if err
          return callback err, null
        if (index = ids.indexOf(delegate.getId().toString())) > -1
          ids.splice(index, 1)
        if ids.length > 0
          trollIds = ('"' + id + '"' for id in ids).join(',')
          callback null, " AND NOT(members.id in ["+trollIds+"])  "
        else
          callback null, ""
    else
      callback null, ""

  @fetch:(query, params, callback)->
    @getDb().query query, params, callback

  @revive:(results, callback)->
    if results.length < 1
      return callback
    data  = []
    for result in results
      if Array.isArray result
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
