neo4j = require "neo4j"

{Graph} = require './index'
QueryRegistry = require './queryregistry'
{race} = require "bongo"

module.exports = class Activity extends Graph

  neo4jFacets = [
    "JLink"
    "JBlogPost"
    "JTutorial"
    "JStatusUpdate"
    "JComment"
    "JOpinion"
    "JDiscussion"
    "JCodeSnip"
    "JCodeShare"
  ]

  # build facet queries
  @generateFacets:(facets)->
    facetQuery = ""
    if facets and 'Everything' not in facets
      facetQueryList = []
      for facet in facets
        return callback new KodingError "Unknown facet: " + facets.join() if facet not in neo4jFacets
        facetQueryList.push("content.name='#{facet}'")
      facetQuery = "AND (" + facetQueryList.join(' OR ') + ")"

    return facetQuery

  @generateTimeQuery:(to)->
    timeQuery = ""
    if to
      timestamp = Math.floor(to / 1000)
      timeQuery = "AND content.`meta.createdAtEpoch` < #{timestamp}"
    return timeQuery

  # generate options
  @generateOptions:(options)->
    {limit, userId, group:{groupName}} = options
    options =
      limitCount: limit or 10
      groupName : groupName
      userId    : "#{userId}"

  @getCurrentGroup: (client, callback)->
    {delegate} = client.connection
    if not delegate
      callback callback {error: "Request not valid"}
    else
      groupName = client.context.group
      JGroup = require '../group'
      JGroup.one slug : groupName, (err, group)=>
        if err then return callback err
        unless group then return callback {error: "Group not found"}
        group.canReadActivity client, (err, res)->
          if err then return callback {error: "Not allowed to open this group"}
          else callback null, group

  # this is used for activities on profile page
  @fetchUsersActivityFeed: (options, callback)->
    {facets, to, limit, client} = options

    @getCurrentGroup client, (err, group)=>
      if err then return callback err
      userId = client.connection.delegate.getId()

      limit = 5 #bandage for now

      groupId = group._id
      groupName = group.slug

      query = [
        "start koding=node:koding(id='#{options.originId}')"
        'MATCH koding<-[:author]-content'
      ]

      whereClause = []
      # build facet queries
      if facets and 'Everything' not in facets
        facetQueryList = []
        for facet in facets
          return callback new KodingError "Unknown facet: " + facets.join() if facet not in neo4jFacets
          facetQueryList.push("content.name='#{facet}'")
        whereClause.push("(" + facetQueryList.join(' OR ') + ")")
      # add timestamp

      if to
        timestamp = Math.floor(to / 1000)
        whereClause.push "content.`meta.createdAtEpoch` < #{timestamp}"

      if whereClause.length > 0
        query.push 'WHERE', whereClause.join(' AND ')

      # add return statement
      query.push "return distinct content"

      if options.sort.likesCount?
        query.push "order by coalesce(content.`meta.likes`?, 0) DESC"
      else if options.sort.repliesCount?
        query.push "order by coalesce(content.repliesCount?, 0) DESC"
      else
        query.push "order by content.`meta.createdAtEpoch` DESC"

      # add limit option
      query.push "LIMIT #{limit}"

      query = query.join('\n')

      @fetch query, options, (err, results) =>
        if err then return callback err
        if results? and results.length < 1 then return callback null, []
        resultData = (result.content.data for result in results)
        @objectify resultData, (objecteds)=>
          @getRelatedContent objecteds, options, callback

  @fetchFolloweeContents:(options, callback)->
    requestOptions = @generateOptions options
    facet = @generateFacets options.facet
    timeQuery = @generateTimeQuery options.to
    query = QueryRegistry.activity.following facet, timeQuery
    @fetch query, requestOptions, (err, results) =>
      if err then return callback err
      if results? and results.length < 1 then return callback null, []
      resultData = (result.content.data for result in results)
      @objectify resultData, (objecteds)=>
        @getRelatedContent objecteds, options, callback



  @getRelatedContent:(results, options, callback)->
    tempRes = []
    {group:{groupName, groupId}, client} = options

    collectRelations = race (i, res, fin)=>
      id = res.getId()
      @fetchRelatedItems id, (err, relatedResult)=>
        clientRelations = reply: 'replies', tag: 'tags', opinion: 'opinions'
        if err
          console.log ">>>>>", err
          return callback err
          fin()
        else
          tempRes[i].relationData =  relatedResult
          tempRes[i].replies = []
          tempRes[i].tags = []
          tempRes[i].opinions = []
          # this works different on following feed and profile page
          for k of relatedResult
            console.log "!!!!!!1---------------------------------------", k
            clientRelName = clientRelations[k]
            if clientRelName?
              for bongoObj in relatedResult[k]
                tempRes[i][clientRelName].push bongoObj
          tempRes[i].repliesCount = tempRes[i].replies?.length or 0
          fin()
    , =>
      if groupName == "koding"
        @removePrivateContent client, groupId, tempRes, (err, cleanContent)=>
          if err 
            console.log ">>>>", err
            return callback err
          revive cleanContent, (revived)=>
            callback null, revived
      else
        # revive tempRes, (revived)=>
        #   console.log "------XXXXXXXXXX------------------------------------"
        #   for obj in revived
        #     console.log obj.data.replies
        #     obj.replies = obj.data.replies
        #   console.log "------------ XXXXXXXXXX --------------------------//"
        callback null, tempRes

    @revive results, (reviveds)->
      for result in reviveds
        tempRes.push result
        collectRelations result

  @fetchRelatedItems: (itemId, callback)->
    query = """
      start koding=node:koding("id:#{itemId}")
      match koding-[r]-all
      return all, r
      order by r.createdAtEpoch DESC
      limit 4
      """
    @fetchRelateds query, callback

  @fetchRelateds:(query, callback)=>
    @fetch query, {}, (err, results) =>
      if err
        console.log "errror errror...", err 
        return callback err
      resultData = []
      for result in results
        type = result.r.type
        data = result.all.data
        console.log ">>>>>>>!!!!!!!!!", type
        data.relationType = type
        resultData.push data

      @objectify resultData, (objected)=>
        respond = {}
        @revive objected, (objects)->
          for obj in objects
            type = obj.data.relationType
            if not respond[type] then respond[type] = []
            respond[type].push obj
          callback err, respond


  @getSecretGroups:(client, callback)->
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
  @removePrivateContent:(client, groupId, contents, callback)->
    if contents.length < 1 then return callback null, contents
    @getSecretGroups client, (err, secretGroups)=>
      if err then return callback err
      if secretGroups.length < 1 then return callback null, contents
      filteredContent = []
      for content in contents
        filteredContent.push content if content.group not in secretGroups
      return callback null, filteredContent



























    ############################################################

  @fetchTagFollows:(group, to, callback)->
    {groupId, groupName} = group
    options =
      groupId   : groupId
      groupName : groupName
      to        : to

    query = QueryRegistry.bucket.newTagFollows
    @fetchFollows query, options, callback

  @fetchFollows:(query, options, callback)->
    @fetch query, options, (err, results)=>
      if err then throw err
      @generateFollows [], results, callback

  @generateFollows:(resultData, results, callback)->
    if results? and results.length < 1 then return callback null, resultData
    result = results.shift()
    data = {}
    @objectify result.follower.data, (objected)=>
      data.follower = objected
      @objectify result.r.data, (objected)=>
        data.relationship = objected
        @objectify result.followees.data, (objected)=>
          data.followee = objected
          resultData.push data
          @generateFollows resultData, results, callback
