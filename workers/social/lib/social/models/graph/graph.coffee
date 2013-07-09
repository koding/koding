neo4j = require "neo4j"
{race} = require 'sinkrow'
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

  neo4jFacets = [
    "JLink"
    "JBlogPost"
    "JTutorial"
    "JStatusUpdate"
    "JOpinion"
    "JDiscussion"
    "JCodeSnip"
    "JCodeShare"
  ]

  fetchAll:(requestOptions, callback)->
    {group:{groupName, groupId}, startDate, client} = requestOptions

    console.time "fetchAll"

    # do not remove white-spaces
    query = """
      START koding=node:koding("id:#{groupId}")
      MATCH koding-[:member]->members<-[:author]-content
      WHERE content.`meta.createdAtEpoch` < #{startDate}
    """

    facets = @facets
    if facets and facets isnt "Everything"
      query += (" AND (content.name=\"#{facets}\")")

    if groupName isnt "koding"
      query += """
        and content.group! = "#{groupName}"

      """
    query += """

      return content
      order by content.`meta.createdAtEpoch` DESC
      limit 20
    """
    @runQuery(query, requestOptions, callback)
    console.timeEnd "fetchAll"

  runQuery:(query, options, callback)->
    {startDate, client} = options
    if options.group?
      {groupName, groupId} = options.group

    @db.query query, {}, (err, results)=>
      tempRes = []
      if err then callback err
      else if results.length is 0 then callback null, []
      else
        collectRelations = race (i, res, fin)=>
          id = res.id
          tempRes[i].replies = [] 
          @fetchRelatedItems id, (err, relatedResult)=>
            if err
              callback err
              fin()
            else
              tempRes[i].relationData =  relatedResult
              if relatedResult.reply?
                for reply in relatedResult.reply
                  reply.bongo_ = 
                    constructorName: obj.name
                    instanceId: obj.id
                  tempRes[i].replies.push reply
              fin()
        , =>

          if groupName? and groupName is "koding"
            @removePrivateContent client, groupId, tempRes, callback
          else
            callback null, tempRes

        resultData = []
        for result in results
          obj = result.content.data
          obj.bongo_ = 
            constructorName: obj.name
            instanceId: obj.id
          resultData.push obj
        console.log "==========================", resultData
        objectify resultData, (objecteds)->
          for objected in objecteds
            tempRes.push objected
            collectRelations objected

  fetchRelatedItems:(itemId, callback)->
    query = """
      start koding=node:koding("id:#{itemId}")
      match koding-[r]-all
      return all, r
      order by r.createdAtEpoch DESC
    """

    @db.query query, {}, (err, results) ->
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

  fetchNewInstalledApps:(group, startDate, callback)->
    console.time 'fetchNewInstalledApps'

    {groupId} = group

    query = """
      START kd=node:koding("id:#{groupId}")
      MATCH kd-[:member]->users<-[r:user]-apps
      WHERE apps.name="JApp"
      and r.createdAtEpoch < #{startDate}
      return users, apps, r
      order by r.createdAtEpoch DESC
      limit 20
      """

    @db.query query, {}, (err, results) =>
      console.timeEnd 'fetchNewInstalledApps'

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
        objectify result.apps.data, (objected)=>
          data.app = objected
          resultData.push data
          @generateInstalledApps resultData, results, callback

  fetchNewMembers:(group, startDate, callback)->
    console.time 'fetchNewMembers'

    {groupId} = group

    query = """
      start  koding=node:koding("id:#{groupId}")
      MATCH  koding-[r:member]->members
      where  r.createdAtEpoch < #{startDate}
      return members
      order by r.createdAtEpoch DESC
      limit 20
      """
    @db.query query, {}, (err, results) ->
        if err then throw err
        resultData = []
        for result in results
          data = result.members.data
          resultData.push data

        objectify resultData, (objected)->
          callback err, objected

          console.timeEnd 'fetchNewMembers'

  fetchMemberFollows:(group, startDate, callback)->
    {groupId} = group
    #followers
    query = """
      start koding=node:koding("id:#{groupId}")
      MATCH koding-[:member]->followees<-[r:follower]-follower
      where follower<-[:member]-koding
      and r.createdAtEpoch < #{startDate}
      return r,followees, follower
      order by r.createdAtEpoch DESC
      limit 20
    """
    @fetchFollows query, callback

  fetchTagFollows:(group, startDate, callback)->
    #followers
    {groupId, groupName} = group
    query = """
      start koding=node:koding("id:#{groupId}")
      MATCH koding-[:member]->followees<-[r:follower]-follower
      where follower.name="JTag"
      and follower.group="#{groupName}"
      and r.createdAtEpoch < #{startDate}
      return r,followees, follower
      order by r.createdAtEpoch DESC
      limit 20
      """
    @fetchFollows query, callback

  fetchFollows:(query, callback)->
    console.time "fetchFollows"

    @db.query query, {}, (err, results)=>
      console.timeEnd "fetchFollows"

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

  getOrderByQuery:(orderBy)->
    orderByQuery = ""
    switch orderBy
      when "counts.followers"
        orderByQuery = "members.`counts.followers`"
      when "counts.following"
        orderByQuery = "members.`counts.following`"
      when "meta.modifiedAt"
        orderByQuery = "members.`meta.modifiedAt`"

    return orderByQuery

  fetchMembers:(options, callback)->
    {skip, limit, sort, groupId} = options
    skip = 0 unless skip
    limit = 20 unless limit

    orderBy = ""
    if sort?
      orderBy = Object.keys(sort)[0]

    orderByQuery = @getOrderByQuery orderBy

    query = """
      START  group=node:koding("id:#{groupId}")
      MATCH  group-[r:member]->members
      return members
      order by #{orderByQuery} DESC
      skip #{skip}
      limit #{limit}
      """
    @queryMembers query, {}, callback

  fetchFollowingMembers:(options, callback)->
    {skip, limit, sort, groupId, currentUserId} = options

    skip = 0 unless skip
    limit = 20 unless limit

    orderBy = Object.keys(sort)[0]
    orderByQuery = @getOrderByQuery orderBy

    query = """
        start  group=node:koding("id:#{groupId}")
        MATCH  group-[r:member]->members-[:follower]->currentUser
        where currentUser.id = "#{currentUserId}"
        return members, r
        order by #{orderByQuery} DESC
        skip #{skip}
        limit #{limit}
        """
    @queryMembers query, {}, callback


  fetchFollowerMembers:(options, callback)->
    {skip, limit, sort, groupId, currentUserId} = options

    skip = 0 unless skip
    limit = 20 unless limit
    orderBy = Object.keys(sort)[0]

    orderByQuery = @getOrderByQuery orderBy

    query = """
        start group=node:koding("id:#{groupId}")
        MATCH group-[r:member]->members<-[:follower]-currentUser
        where currentUser.id = "#{currentUserId}"
        return members, r
        order by #{orderByQuery} DESC
        skip #{skip}
        limit #{limit}
        """
    @queryMembers query, {}, callback

  queryMembers:(query, options={}, callback)->
    @db.query query, options, (err, results) ->
        if err then throw err
        resultData = []
        for result in results
          data = result.members.data
          id = data.id
          name = data.name
          obj =  {id : id, name : name }
          resultData.push obj

        callback err, resultData
