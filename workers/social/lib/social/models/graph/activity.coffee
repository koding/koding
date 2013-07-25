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
        return callback new KodingError "Unknown facet: #{facets.join()}" if facet not in neo4jFacets
        facetQueryList.push "content.name='#{facet}'"
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



  # this function gets request options to fetch public content on main page
  # for all groups it is called when it has "Public" filter in it
  # It can filter also with facets like: "Everything, Status Updates, Discussions"
  @fetchAll:(requestOptions, callback)->
    {group:{groupName, groupId}, startDate, client, facet} = requestOptions
    queryOptions =
      groupId : groupId
      to  : startDate
      limitCount : 20

    facetQuery = groupFilter = ""

    if facet and facet isnt "Everything"
      queryOptions.facet = facet
      facetQuery += "AND content.name = {facet}"

    if groupName isnt "koding"
      queryOptions.groupName = groupName
      groupFilter = "AND content.group! = {groupName}"

    query = QueryRegistry.activity.public facetQuery, groupFilter

    @fetchWithRelatedContent query, queryOptions, requestOptions, callback



  # this is used for activities on profile page
  @fetchUsersActivityFeed: (requestOptions, callback)->
    requestOptions.group =
      grouId : requestOptions.group.id
      groupName : requestOptions.group.slug

    {facets, to, limit, client} = requestOptions
    facetQuery = @generateFacets facets

    if requestOptions.sort.likesCount?
      orderBy = "coalesce(content.`meta.likes`?, 0)"
    else if requestOptions.sort.repliesCount?
      orderBy = "coalesce(content.repliesCount?, 0)"
    else
      orderBy = "content.`meta.createdAtEpoch`"

    # todo check for options that are required for this query
    queryOptions = requestOptions
    queryOptions.userId = requestOptions.originId
    queryOptions.limitCount = 3 #requestOptions.limit
    query = QueryRegistry.activity.profilePage {facetQuery, orderBy}
    @fetchWithRelatedContent query, queryOptions, requestOptions, callback

  # this is following feed on main page
  @fetchFolloweeContents:(requestOptions, callback)->
    queryOptions = @generateOptions requestOptions
    facet = @generateFacets requestOptions.facet
    timeQuery = @generateTimeQuery requestOptions .to
    query = QueryRegistry.activity.following facet, timeQuery
    @fetchWithRelatedContent query, queryOptions, requestOptions, callback

  @fetchWithRelatedContent: (query, queryOptions, requestOptions, callback)->
    @fetch query, queryOptions, (err, results) =>
      if err then return callback err
      if results? and results.length < 1 then return callback null, []
      resultData = (result.content.data for result in results)
      @objectify resultData, (objecteds)=>
        @getRelatedContent objecteds, requestOptions, callback

  @getRelatedContent:(results, options, callback)->
    tempRes = []
    {group:{groupName, groupId}, client} = options
    @collectRelations = race (i, res, fin)=>
      @fetchRelatedItems res, (err, relatedResult)=>
        clientRelations = reply: 'replies', tag: 'tags', opinion: 'opinions'
        if err
          return callback err
          fin()
        else
          # this works different on following feed and profile page
#          tempRes[i].relationData =  relatedResult
          tempRes[i][v] = [] for k, v of clientRelations
          for k of relatedResult
            clientRelName = clientRelations[k]
            if clientRelName?
              for bongoObj in relatedResult[k]
                tempRes[i][clientRelName].push bongoObj
              tempRes[i][clientRelName].reverse()
          fin()
    , =>
      if groupName == "koding"
        @removePrivateContent client, groupId, tempRes, (err, cleanContent)=>
          if err then return callback err
          callback null, cleanContent
      else
        callback null, tempRes

    @revive results, (reviveds)=>
      for revived in reviveds
        tempRes.push revived
        @collectRelations revived

  @fetchRelatedItems: (item, callback)->
    # IMPORTANT
    # this gives "range error maximum recursion depth exceeded",
    # if we dont set the relation types
    # probably because there maybe self referencing objects
    # to test just remove tag|reply|opinion part
    query = """
      start koding=node:koding("id:#{item.getId()}")
      match koding-[r:tag|reply|opinion]-all
      return all, r
      order by r.createdAtEpoch DESC
      """
    @fetchRelateds item, query, callback

  @fetchRelateds:(item, query, callback)=>
    @fetch query, {}, (err, results) =>
      if err
        return callback err

      if results.length < 1
        item.repliesCount = 0
        return callback null, results

      relationTypes = ['tag', 'reply', 'opinion']
      counts = {}
      counts[k] = 0 for k in relationTypes

      item.repliesCount = 0
      resultData = []
      for result in results
        # we need to set items reply count
        item.repliesCount++ if result.r.type is 'reply'
        # we are removing the unneeded content here
        if result.r.type in relationTypes and counts[result.r.type]++<3
          type = result.r.type
          data = result.all.data
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
