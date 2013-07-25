_ = require 'underscore'
neo4j = require "neo4j"

{Base, ObjectId, race} = require 'bongo'

module.exports = class Graph
  constructor:({config, facets})->
    @db = new neo4j.GraphDatabase(config.read + ":" + config.port);
    @facets = facets

  fetchObjectsFromMongo:(collections, wantedOrder, callback)->
    sortThem=(err, objects)->
      if err
        callback(err)
        return
      ret = []
      for i in wantedOrder
        obj = objects[i.idx]
        if obj
          ret.push(obj)
        else
          console.log("id in neo4j but not in mongo, maybe a sync problem ??? " + i.idx)
      callback null, ret

    ret = {}
    collectObjects = race (i, res, fin)->
      res.klass.all res.selector, (err, objects)->
        if err then callback err
        else
          for o in objects
            ret[o._id + '_' + res.modelName] = o
        fin()
    , -> sortThem null, ret

    for modelName of collections
      ids = collections[modelName]
      klass = Base.constructors[modelName]
      selector = {
        _id:
          $in: ids.map (id)->
            if 'string' is typeof id then ObjectId(id)
            else id
      }
      collectObjects({klass:klass, selector:selector, modelName:modelName})

  # returns object ids from a result set as array
  # returns dict {colections: {'users':[id1,id2,id3]},
  #               wantedOrder: ['users_id1', 'users_id2']
  #             }
  # this is needed for fetchObjectsFromMongo()
  getIdsFromAResultSet: (resultSet)->
    collections = {}
    wantedOrder = []
    for obj in resultSet
      collections[obj.name] or= []
      collections[obj.name].push obj.id
      wantedOrder.push idx: obj.id+'_'+obj.name
    collections: collections, wantedOrder: wantedOrder


  attachReplies:(options, callback)->
    tempRes = []
    collectRelations = race (i, res, fin)=>
      res.replies = []
      @fetchReplies res.getId(), (err, relatedResult)=>
        if err
          callback err
          fin()
        else
            if relatedResult.reply?
              {collections, wantedOrder} = @getIdsFromAResultSet relatedResult.reply
              @fetchObjectsFromMongo collections, wantedOrder, (err, dbObjects)->
                res.replies.push obj for obj in dbObjects
                tempRes[i] = res
                fin()
            else
              tempRes.push res
              fin()
    , =>
      {groupName, groupId} = options.group if options.group?
      {client} = options

      if groupName? and groupName is "koding"
        @removePrivateContent client, groupId, tempRes, callback
      else
        callback null, tempRes
    return collectRelations

  runQuery:(query, options, callback)->
    @db.query query, {}, (err, results)=>
      if err
        callback err
      else if results.length is 0 then callback null, []
      else
        collectRelations = @attachReplies(options, callback)
        resultData = []
        {collections, wantedOrder} = @getIdsFromAResultSet _.map(results, (e)->e.content.data)
        @fetchObjectsFromMongo collections, wantedOrder, (err, dbObjects)->
          for dbObj in dbObjects
            collectRelations dbObj

  revive:(results, callback)->
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

  revive2:(results)->
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
    data


  objectify: (incomingObjects, callback)->
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


  fetchAll:(requestOptions, callback)->
    requestOptions.facet = @facets
    mainFeed = require "./activity"
    mainFeed.fetchAll requestOptions, callback

  fetchReplies: (itemId, callback)->
    query = """
      start koding=node:koding("id:#{itemId}")
      match koding-[r:reply]-all
      return all, r
      order by r.createdAtEpoch DESC
      limit 3
    """
    @fetchRelateds query, callback


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
