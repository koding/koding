neo4j = require "neo4j"
{race} = require 'sinkrow'

module.exports = class Graph
  constructor:(config)->
    @groupId = KD?.getSingleton('groupsController')?.getCurrentGroup()?.getId() or "5150c743f2589b107d000007"
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

  fetchAll:(startDate, endDate, callback)->
    start = new Date().getTime()
    query = [
      'start koding=node:koding(\'id:*\')'
      'where koding.name = "JTutorial"'
      ' or koding.name = "JCodeSnip"'
      ' or koding.name = "JDiscussion"'
      ' or koding.name = "JStatusUpdate"'
      #'and koding.`meta.createdAt` > {startDate} and koding.`meta.createdAt` < {endDate}'
      'return *'
      'order by koding.`meta.createdAt` DESC'
      'limit 20'
    ].join('\n');

    params =
      groupId   : @groupId
      startDate : startDate
      endDate   : endDate

    @db.query query, params, (err, results)=>

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

  fetchNewInstalledApps:(callback)->
    query = [
      'start koding=node:koding(\'id:*\')'
      'match koding-[r:user]->users'
      'where koding.name="JApp" and r.createdAt > "2012-11-14T23:56:48Z"'
      'return *'
      'order by r.createdAt DESC'
      'limit 40'
    ].join('\n');

    @db.query query, {}, (err, results) =>
      if err then throw err
      @generateInstalledApps [], results, callback

  generateInstalledApps:(resultData, results, callback)->
    if results? and results.length < 1 then return callback null, resultData
    result = results.shift()
    data = {}
    objectify result.users.data, (objected)=>
      data.user = objected
      objectify result.r.data, (objected)=>
        data.relationship = objected
        objectify result.koding.data, (objected)=>
          data.app = objected
          resultData.push data
          @generateInstalledApps resultData, results, callback

  fetchNewMembers:(callback)->
    query = [
      'start  koding=node:koding(id={groupId})'
      'MATCH  koding-[r:member]->members'
      'where  members.name="JAccount" and r.createdAt > {startDate} and r.createdAt < {endDate}'
      'return members'
      'order by koding.`meta.createdAt` DESC'
      'limit 40'
    ].join('\n');

    params =
      groupId   : @groupId
      startDate : "2012-02-14T23:56:48Z"
      endDate   : "2014-02-14T23:56:48Z"

    @db.query query, params, (err, results) ->
        if err then throw err
        resultData = []
        for result in results
          data = result.members.data
          resultData.push data

        objectify resultData, (objected)->
          callback err, objected



  fetchNewFollows:(callback)->
    #followers
    query = [
      'start koding=node:koding(id={groupId})'
      'MATCH koding-[:member]->followees<-[r:follower]-follower'
      'where followees.name="JAccount" and r.createdAt > {startDate} and r.createdAt < {endDate}'
      'return r,followees, follower'
      'order by r.createdAt DESC'
      'limit 10'
    ].join('\n');

    params =
      groupId   : @groupId
      startDate : "2012-02-14T23:56:48Z"
      endDate   : "2014-02-14T23:56:48Z"

    @db.query query, params, (err, results)=>
      if err then throw err
      @generateFollows [], results, callback

  generateFollows:(resultData, results, callback)->

    if results? and results.length < 1 then return callback null, resultData
    result = results.shift()
    data = {}
    objectify result.follower.data, (objected)=>
      data.follower = objected
      objectify result.r.data, (objected)=>
        data.relationship = objected
        objectify result.followees.data, (objected)=>
          data.followee = objected
          resultData.push data
          @generateFollows resultData, results, callback
