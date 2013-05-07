neo4j = require "neo4j"
{race} = require 'sinkrow'

module.exports = class Graph 
  constructor:(config)->
    @db = new neo4j.GraphDatabase(config.host + ":" + config.port);

  objectify = (incomingObjects, callback)->
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

  fetchAll:(callback)->
    start = new Date().getTime()
    query = [
      'start koding=node:koding(\'id:*\')'
      'where koding.name = "JTutorial"'
      ' or koding.name = "JCodeSnip"' 
      ' or koding.name = "JDiscussion"' 
      ' or koding.name = "JStatusUpdate"' 
      'return *'
      'order by koding.`meta.createdAt` DESC'
      'limit 4'  
    ].join('\n');

    params =
      itemId : "515360d23af2fb6b6b000009" 

    @db.query query, params, (err, results)=>
#      console.log results
      tempRes = []
      if err then callback err
      else if results.length is 0 then callback null, []
      else
        collectRelations = race (i, res, fin)=>
          id = res.id

          @fecthRelatedItems id, (err, relatedResult)=>
            if err
              callback err
              fin()
            else
              tempRes[i].relationData =  relatedResult
              fin()
        , ->
          console.log new Date().getTime() - start
          callback null, tempRes
        resultData = ( result.koding.data for result in results)  
        objectify resultData, (objecteds)->
          for objected in objecteds
            tempRes.push objected
            collectRelations objected 

  fecthRelatedItems:(itemId, callback)->
    query = [
      'start koding=node:koding(id={itemId})'
      'match koding-[r]-all'
      'return *'
      'order by koding.`meta.createdAt` DESC'
    ].join('\n');

    params =
      itemId : itemId

    
    @db.query query, params, (err, results) ->
      if err then throw err
      resultData = []
      for result in results
        type = result.r.type
        data = result.all.data
        data.relationType = type
        resultData.push data

      objectify resultData, (objected)->
        respond = {}
        for obj in objected
          type = obj.relationType
          if not respond[type] then respond[type] = []
          respond[type].push obj
        callback err, respond
