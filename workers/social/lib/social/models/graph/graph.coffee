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
                tempRes.push res
                fin()
            else
              tempRes.push res
              fin()
    , =>
      {groupName, groupId} = options.group if options.group?

      if groupName? and groupName is "koding"
        @removePrivateContent client, groupId, tempRes, callback
      else
        callback null, tempRes
    return collectRelations

  runQuery:(query, options, callback)->
    {startDate, client} = options
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

  getSecretGroups:(client, callback)->
    JGroup = require '../group'
    JGroup.some
      $or : [
        { privacy: "private" }
        { visibility: "hidden" }
      ]
      slug:
        $nin: ["koding"] # we need koding even if its private
    , {}, (err, groups)=>
      if err then return callback err
      else
        if groups.length < 1 then callback null, []
        secretGroups = []
        checkUserCanReadActivity = race (i, {client, group}, fin)=>
          group.canReadActivity client, (err, res)=>
            secretGroups.push group.slug if err
            fin()
        , -> callback null, secretGroups
        for group in groups
          checkUserCanReadActivity {client: client, group: group}

  # we may need to add public group's read permission checking
  removePrivateContent:(client, groupId, contents, callback)->
    if contents.length < 1 then return callback null, contents
    @getSecretGroups client, (err, secretGroups)=>
      if err then return callback err
      if secretGroups.length < 1 then return callback null, contents
      filteredContent = []
      for content in contents
        filteredContent.push content if content.group not in secretGroups
      return callback null, filteredContent

  fetchAll:(requestOptions, callback)->
    {group:{groupName, groupId}, startDate, client} = requestOptions

    # do not remove white-spaces
    query = """
      START koding=node:koding("id:#{groupId}")
      MATCH koding-[:member]->members<-[:author]-content
      WHERE content.`meta.createdAtEpoch` < #{startDate}
    """

    facets = @facets
    if facets and facets isnt "Everything"
      query += (" AND (content.name=\"#{facets}\")")

# =======
#     if facets and "Everything" not in facets
#       facetQueryList = []
#       for facet in facets
#         if facet not in neo4jFacets
#           console.log "Unknown facet: " + facets.join()
#           continue

#         facetQueryList.push("content.name=\"#{facet}\"")

#       query += (" AND (" + facetQueryList.join(' OR ') + ")")
# >>>>>>> Stashed changes

    if groupName isnt "koding"
      query += """
        and content.group! = "#{groupName}"

      """
    query += """

      return content
      order by content.`meta.createdAtEpoch` DESC
      limit 20
    """
    @db.query query, {}, (err, results)=>
      tempRes = []
      if err then callback err
      else if results.length is 0 then callback null, []
      else
        collectRelations = race (i, res, fin)=>
          id = res.id

          @fetchRelatedItems id, (err, relatedResult)=>
            if err
              callback err
              fin()
            else
              tempRes[i].relationData =  relatedResult
              fin()
        , =>
          if groupName == "koding"
            @removePrivateContent client, groupId, tempRes, callback
          else
            callback null, tempRes
        resultData = ( result.content.data for result in results)
        objectify resultData, (objecteds)->
          for objected in objecteds
            tempRes.push objected
            collectRelations objected

  fetchRelateds: (query, callback)->
    @db.query query, {}, (err, results) ->
      if err then callback err
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



  fetchReplies: (itemId, callback)->
    query = """
      start koding=node:koding("id:#{itemId}")
      match koding-[r:reply]-all
      return all, r
      order by r.createdAtEpoch DESC
      limit 2
    """
    @fetchRelateds query, callback

  fetchRelatedItems:(itemId, callback)->
    query = """
      start koding=node:koding("id:#{itemId}")
      match koding-[r]-all
      return all, r
      order by r.createdAtEpoch DESC
    """
    @fetchRelateds query, callback


  fetchInvitations:(options, callback)->
    {groupId, status, timestamp, requestLimit, search} = options

    requestLimit = 10 unless requestLimit
    regexSearch  = ""
    timeStampQuery = ""

    if search
      # search = search.replace(/[^\w\s@.+-]/).replace(/([+.]+)/g, "\\$1").trim()
      search = search.replace(/[^\w\s@.+-]/).trim()
      regexSearch = "AND groupOwnedNodes.email =~ \".*#{search}.*\""

    if timestamp?
        timeStampQuery = "AND groupOwnedNodes.requestedAt > \"#{timestamp}\""

    if typeof status is "string" then status = [status]

    # convert status array into string array
    status   = "[\"" + status.join("\",\"") + "\"]"

    query = """
        START group=node:koding("id:#{groupId}")
        MATCH group-[r:owner]->groupOwnedNodes
        WHERE groupOwnedNodes.name = 'JInvitationRequest'
        AND groupOwnedNodes.status IN #{status}
        #{timeStampQuery}
        #{regexSearch}
        RETURN groupOwnedNodes
        ORDER BY groupOwnedNodes.`meta.createdAtEpoch`
        LIMIT #{requestLimit}
        """

    @db.query query, {}, callback

