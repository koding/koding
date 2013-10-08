_ = require 'underscore'
neo4j = require "neo4j-koding"
{race} = require 'sinkrow'
{Base, ObjectId, race} = require 'bongo'

JCache = require '../cache.coffee'

module.exports = class Graph
  constructor:({config, facets})->
    @db = new neo4j.GraphDatabase "#{config.read}:#{config.port}"
    @facets = facets

  @reviveFromData: (data, className)->
    data.bongo_ =
      constructorName : className
      instanceId : data.id
    data._id = data.id
    obj = new Base.constructors[className] data
    return obj

  fetchObjectsFromMongo:(collections, wantedOrder, callback)->
    sortThem=(err, objects)->
      if err
        callback(err)
        return
      ret = []
      for i in wantedOrder
        obj = objects[i.idx]
        if obj
          ret.push obj
        else
          console.log "id in neo4j but not in mongo, maybe a sync problem ??? #{i.idx}"
      callback null, ret

    ret = {}
    collectObjects = race (i, res, fin)->
      res.klass.all res.selector, (err, objects)->
        if err then callback err
        else
          ret[o._id + '_' + res.modelName] = o  for o in objects
        fin()
    , -> sortThem null, ret

    for modelName of collections
      ids = collections[modelName]
      klass = Base.constructors[modelName]
      selector = {
        _id: $in: ids.map (id)->
          if 'string' is typeof id then ObjectId(id)
          else id
      }
      collectObjects { klass, selector, modelName }

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
              tempRes[i] = res
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
        console.log ">>> err", query, err
        return callback err
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
      return callback err if err
      return callback null, [] if groups.length < 1
      secretGroups =  (group.slug for group in groups)
      callback null, secretGroups

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

  getExemptUsersClauseIfNeeded: (requestOptions, callback)->
    if not requestOptions.withExempt
      {delegate} = requestOptions.client.connection
      JAccount = require '../account'
      JAccount.getExemptUserIds (err, ids)=>
        return callback err, null if err
        trollIds = ('"' + id + '"' for id in ids when id.toString() isnt delegate.getId().toString()).join(',')
        if trollIds.length > 0
          callback null, " AND NOT(members.id in ["+trollIds+"])  "
        else
          callback null, ""
    else
      callback null, ""

  fetchAll:(requestOptions, callback)->
    {group:{groupName, groupId}, startDate, client} = requestOptions

    # do not remove white-spaces
    query = """
      START koding=node:koding("id:#{groupId}")
      MATCH koding-[:member]->members<-[:author]-content
      WHERE content.`meta.createdAtEpoch` < {startDate}
      """

    facets = @facets
    if facets and facets isnt "Everything"
      query += (" AND (content.name=\"#{facets}\")")

    if groupName isnt "koding"
      query += """
        and content.group! = "#{groupName}"

      """

    @getExemptUsersClauseIfNeeded requestOptions, (err, exemptClause)=>
      return callback err, null if err

      query += """
        #{exemptClause}
        return content
        order by content.`meta.createdAtEpoch` DESC
        limit 20
      """

      returnResults = (err, results)=>

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

      JCache.get query, (err, results)=>
        if err or not results
          @db.query query, {startDate}, (err, results)=>
            JCache.add query, results
            returnResults(err, results)
        else
          returnResults(err, results)

  fetchRelateds: (query, callback)->
    @db.query query, {}, (err, results) ->
      if err
        console.log ">>> err fetchRelateds error", query, err
        return callback err
      resultData = []
      results.reverse()
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
      limit 3
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

  fetchNewInstalledApps:(group, startDate, callback)->
    {groupId} = group

    query = """
      START kd=node:koding("id:#{groupId}")
      MATCH kd-[:member]->users<-[r:user]-apps
      WHERE apps.name="JApp"
      and r.createdAtEpoch < {startDate}
      return users, apps, r
      order by r.createdAtEpoch DESC
      limit 20
      """

    @db.query query, {startDate}, (err, results)=>
      if err
        console.log ">>> err fetchNewInstalledApps", query, err
        return callback err
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

  searchMembers:(options, callback)->
    {groupId, seed, firstNameRegExp, lastNameRegexp, skip, limit, blacklist} = options

    activity = require '../activity/index'

    activity.getCurrentGroup options.client, (err, group)=>
      if err
        return callback err

      query = """
        START  koding=node:koding("id:#{group.getId()}")
        MATCH  koding-[r:member]->members

        WHERE  (
          members.`profile.nickname` =~ '(?i)#{seed}'
          or members.`profile.firstName` =~ '(?i)#{firstNameRegExp}'
          or members.`profile.lastName` =~ '(?i)#{lastNameRegexp}'
        )
        """
      query += " \n"

      if blacklist? and blacklist.length
        blacklistIds = ("'#{id}'" for id in blacklist).join(',')
        query += " AND NOT( members.id IN [#{ blacklistIds }] ) \n"

      query += " RETURN members \n"
      query += " ORDER BY members.`profile.firstName` "

      query += " SKIP #{skip} \n" if skip
      query += " LIMIT #{limit} \n" if limit

      @db.query query, {}, (err, results) =>
        if err
          console.log ">>> err search members", query, err
          return callback err
        else if results.length is 0 then callback null, []
        else
          objectify results[0].members.data, (objected)=>
            {collections, wantedOrder} = @getIdsFromAResultSet [objected]
            @fetchObjectsFromMongo collections, wantedOrder, (err, dbObjects)->
              callback err, dbObjects

  fetchNewMembers:(group, startDate, callback)->
    {groupId} = group

    query = """
      start  koding=node:koding("id:#{groupId}")
      MATCH  koding-[r:member]->members
      where  r.createdAtEpoch < {startDate}
      return members
      order by r.createdAtEpoch DESC
      limit 20
      """

    @db.query query, {startDate}, (err, results) ->
      if err
        console.log ">>> err fetchNewMembers", query, err
        return callback err, null
      resultData = []
      for result in results
        data = result.members.data
        resultData.push data

      objectify resultData, (objected)->
        callback err, objected

  fetchMemberFollows:(group, startDate, callback)->
    {groupId} = group
    #followers
    query = """
      start koding=node:koding("id:#{groupId}")
      MATCH koding-[:member]->followees<-[r:follower]-follower
      where follower<-[:member]-koding
      and r.createdAtEpoch < {startDate}
      return r,followees, follower
      order by r.createdAtEpoch DESC
      limit 20
    """
    @fetchFollows query, startDate, callback

  fetchTagFollows:(group, startDate, callback)->
    #followers
    {groupId, groupName} = group
    query = """
      start koding=node:koding("id:#{groupId}")
      MATCH koding-[:member]->followees<-[r:follower]-follower
      where follower.name="JTag"
      and follower.group="#{groupName}"
      and r.createdAtEpoch < {startDate}
      return r,followees, follower
      order by r.createdAtEpoch DESC
      limit 20
      """
    @fetchFollows query, startDate, callback

  fetchFollows:(query, startDate, callback)->
    @db.query query, {startDate}, (err, results)=>
      if err
        console.log ">>> err fetchFollows", query, err
        return callback err
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

  generateOrderByQuery:(sort)->
    orderByQuery = ''
    if sort
      orderBy = Object.keys(sort)[0]
      orderByQuery = "ORDER BY #{@getOrderByQuery orderBy} DESC"

    return orderByQuery

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


  countMembers:(options, callback)->
    {groupId} = options

    query = """
      START  group=node:koding("id:#{groupId}")
      MATCH  group-[r:member]->members
      RETURN count(members) as count
      """
    @db.query query, options, (err, results) ->
      if err
        console.log ">>> err", query, err
        return callback err
      count = if results and results[0]['count'] then results[0]['count'] else 0
      callback null, count

  fetchMembers:(options, callback)->
    {skip, limit, sort, groupId} = options

    skip   ?= 0
    limit  ?= 20

    query = """
      START  group=node:koding("id:#{groupId}")
      MATCH  group-[r:member]->members
      WHERE members.name = 'JAccount'
    """

    @getExemptUsersClauseIfNeeded options, (err, exemptClause)=>
      if err
        return callback err, null

      query += """
        #{exemptClause}
        return members
        #{@generateOrderByQuery sort}
        skip #{skip}
        limit #{limit}
        """
      @queryMembers query, {}, callback

  fetchFollowingMembers:(options, callback)->
    {skip, limit, sort, groupId, currentUserId} = options

    skip   ?= 0
    limit  ?= 20

    query = """
        START  group=node:koding("id:#{groupId}")
        MATCH  group-[r:member]->members-[:follower]->currentUser
        WHERE currentUser.id = "#{currentUserId}"
        RETURN members, r
        #{@generateOrderByQuery sort}
        SKIP #{skip}
        LIMIT #{limit}
        """
    @queryMembers query, {}, callback


  fetchFollowerMembers:(options, callback)->
    {skip, limit, sort, groupId, currentUserId} = options

    skip   ?= 0
    limit  ?= 20

    query = """
        START group=node:koding("id:#{groupId}")
        MATCH group-[r:member]->members<-[:follower]-currentUser
        WHERE currentUser.id = "#{currentUserId}"
        RETURN members, r
        #{@generateOrderByQuery sort}
        SKIP #{skip}
        LIMIT #{limit}
        """
    @queryMembers query, {}, callback

  getFetchOrCountInvitationsQuery = (method, options)->
    {groupId, search, query, status, searchField, model} = options

    if search
      search = search.replace(/[^\w\s@.+-]/).trim()
      regexSearch = "AND groupOwnedNodes.#{searchField} =~ \".*#{search}.*\""

    if status
      statusQuery = "AND groupOwnedNodes.status = '#{options.status}'"

    query =
      """
      START group=node:koding("id:#{groupId}")
      MATCH group-[r:owner]->groupOwnedNodes
      WHERE groupOwnedNodes.name = '#{model}'
      #{query ? ''}
      #{statusQuery ? ''}
      #{regexSearch ? ''}
      """

    if method is 'fetch'
      {timestamp, requestLimit, timestampField} = options

      if timestamp?
        timestampQuery = "AND groupOwnedNodes.#{timestampField} > \"#{timestamp}\""

      query +=
        """
        #{timestampQuery ? ''}
        RETURN groupOwnedNodes
        ORDER BY groupOwnedNodes.`meta.createdAtEpoch`
        LIMIT #{requestLimit ? 10}
        """
    else
      query += "RETURN count(groupOwnedNodes) as count"

    return query

  fetchOrCountInvitationRequests:(method, options, callback)->
    options.model          = 'JInvitationRequest'
    options.timestampField = 'requestedAt'
    options.searchField    = 'email'
    options.query          = 'AND has(groupOwnedNodes.username)'

    query = getFetchOrCountInvitationsQuery method, options
    @db.query query, {}, callback

  fetchOrCountInvitations:(method, options, callback)->
    options.model          = 'JInvitation'
    options.timestampField = 'createdAt'
    options.searchField    = 'email'
    options.query          = "AND groupOwnedNodes.type = 'admin'"

    query = getFetchOrCountInvitationsQuery method, options
    console.log query
    @db.query query, {}, callback

  fetchOrCountInvitationCodes:(method, options, callback)->
    options.model          = 'JInvitation'
    options.timestampField = 'createdAt'
    options.searchField    = 'code'
    options.query          = "AND groupOwnedNodes.type = 'multiuse'"

    query = getFetchOrCountInvitationsQuery method, options
    @db.query query, {}, callback

  queryMembers:(query, options={}, callback)->
    @db.query query, options, (err, results) ->
      if err
        console.log ">>> err queryMembers", query, err
        return callback err
      resultData = []
      for result in results
        data = result.members.data
        id = data.id
        name = data.name
        obj =  {id : id, name : name }
        resultData.push obj

      callback err, resultData

  ## NEWER IMPLEMENATION: Fetch ids from graph db, get items from document db.

  fetchRelatedTagsFromGraph: (options, callback)->
    {userId} = options

    query = """
      START follower=node:koding("id:#{userId}")
      MATCH follower-[:related]->oauth-[r:github_followed_JTag]->followees
      return followees.id as id
    """

    JTag = require "../tag"
    @fetchItems query, JTag, callback

  fetchRelatedUsersFromGraph: (options, callback)->
    {userId} = options

    query = """
      START follower=node:koding("id:#{userId}")
      MATCH follower-[:related]->oauth-[r:github_followed_JUser]->followees
      return followees.id as id
    """

    JUser = require "../user"
    @fetchItems query, JUser, callback

  fetchItems:(query, modelName, callback)->
    @db.query query, {}, (err, results)=>
      if err
        console.log ">>> err fetchItems", query, err
        return callback err
      else
        tempRes = []
        collectContents = race (i, id, fin)=>
          modelName.one  { _id : id }, (err, account)=>
            if err
              callback err
              fin()
            else
              tempRes[i] =  account
              fin()
        , ->
          callback null, tempRes
        for res in results
          collectContents res.id

  fetchRelationshipCount:(options, callback)->
    {groupId, relName} = options
    query = """
      START group=node:koding("id:#{groupId}")
      match group-[:#{relName}]->items
      return count(items) as count
    """

    @db.query query, {}, (err, results) ->
      if err
        console.log ">>> err fetchRelationshipCount", query, err
        callback err, null
      else callback null, results[0].count
