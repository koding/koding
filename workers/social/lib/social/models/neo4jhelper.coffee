neo4j = require "neo4j"

module.exports = class Neo4jHelper
  {Base, ObjectId, race, dash, secure} = require 'bongo'

  @fetchObjectsFromMongo:(collections, wantedOrder, callback)->
    sortThem=(err, objects)->
      if err
        callback(err)
        return
      ret = []
      for i in wantedOrder
        obj = objects[i['idx']]
        if obj
          ret.push(obj)
        else
          console.log("!!!!!!!! id in neo4j but not in mongo, maybe a sync problem ??? " + i['idx'])
      callback null, ret

    ret = {}
    collectObjects = race (i, res, fin)->
      res.klass.all res.selector, (err, objects)->
        if err then callback err
        else
          for o in objects
            ret[o['_id'] + '_' + res.modelName] = o
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

  @fetchFromNeo4j:(query, params, callback)->
    # gets ids from neo4j, fetches objects from mongo, returns in the same order
    neo4jConfig = KONFIG['neo4j']
    resultsKey = params['resultsKey'] or "items"
    @db = new neo4j.GraphDatabase(neo4jConfig.host + ":" + neo4jConfig.port);
    @db.query query, params, (err, results)=>
      if err
        console.log("error in neo4j query: " + err)
        console.log("query was ==================")
        console.log(query)
        console.log("============================")
        return callback err

      if results.length == 0
        callback null, []
      console.log("4")
      wantedOrder = []
      collections = {}
      for result in results
        oid = result[resultsKey]["_data"]["data"]["id"]
        otype = result[resultsKey]["_data"]["data"]["name"]
        wantedOrder.push({id: oid, collection: otype, idx: oid+'_'+otype})
        collections[otype] ||= []
        collections[otype].push(oid)
      @fetchObjectsFromMongo(collections, wantedOrder, callback)

