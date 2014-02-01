{Graph} = require './index'
QueryRegistry = require './queryregistry'
{race} = require "bongo"
KodingError = require "./../../error"

module.exports = class Activity extends Graph

  neo4jFacets = [
    "JNewStatusUpdate"
#    "JLink"
#    "JBlogPost"
#    "JTutorial"
#    "JComment"
#    "JOpinion"
#    "JDiscussion"
#    "JCodeSnip"
#    "JCodeShare"
  ]

  # build facet queries
  @generateFacets:(options)->
    return throw new KodingError "Facet is not defined in query options" unless options.facet

    {facet} = options
    return "" if facet is 'Everything'
    return throw new KodingError "Unknown facet: #{facet}" if facet not in neo4jFacets
    return "AND content.name='#{facet}' "

  @generateTimeQuery:(options)->
    return throw new KodingError "-to- is not defined in query options" unless options.to

    timestamp = Math.floor(options.to / 1000)
    timeQuery = "AND content.`meta.createdAtEpoch` < #{timestamp}"
    return timeQuery

  # generate options
  @generateOptions:(options, group)->
    {limit, userId} = options
    options =
      limitCount: limit or 10
      groupName : group.slug
      userId    : "#{userId}"
    return options
  # generate request options
  # this will return current group and
  # client object
  @generateRequestOptions:(client, group)->

    requestOptions =
      group     :
        groupName : group.slug
        groupId   : group._id
      client    : client

    return requestOptions

  @getCurrentGroup: (client, callback)->
    {delegate} = client.connection
    if not delegate
      callback callback {error: "Request not valid"}
    else
      groupName = client.context.group or "koding"
      JGroup = require '../group'
      JGroup.one slug : groupName, (err, group)=>
        if err then return callback err
        unless group then return callback {error: "Group not found"}
        group.canReadGroupActivity client, (err, res)->
          if err then return callback {error: "Not allowed to open this group"}
          else callback null, group



  # this function gets request options to fetch public content on main page
  # for all groups it is called when it has "Public" filter in it
  # It can filter also with facets like: "Everything, Status Updates, Discussions"
  @fetchAll:(requestOptions, callback=->)->
    {group:{groupName, groupId}, startDate, client, facet} = requestOptions
    queryOptions =
      groupId : groupId
      to  : startDate
      limitCount : KONFIG.client.runtimeOptions.activityFetchCount

    facetQuery = groupFilter = ""

    if facet and facet isnt "Everything"
      queryOptions.facet = facet
      facetQuery += "AND content.name = {facet}"

    if groupName isnt "koding"
      queryOptions.groupName = groupName
      groupFilter = "AND content.group! = {groupName}"

    @getExemptUsersClauseIfNeeded (@createExemptOptions requestOptions), (err, exemptClause)=>
      query = QueryRegistry.activity.public facetQuery, groupFilter, exemptClause
      queryOptions.client = client # we need this to remove private content
      @fetchWithRelatedContent query, queryOptions, requestOptions, callback

  @createExemptOptions:(options)->
    return {client : options.client, withExempt : options.withExempt}

  # this is used for activities on profile page
  @fetchUsersActivityFeed: (requestOptions, callback)->
    @getCurrentGroup requestOptions.client, (err, currentGroup)=>
      if err
        console.log "fetchUsersActivityFeed err:", err
        return callback err

      requestOptions.group = {groupName: currentGroup.slug, groupId: currentGroup._id}

      facetQuery = @generateFacets requestOptions

      if requestOptions.sort.likesCount?
        orderBy = "coalesce(content.`meta.likes`?, 0)"
      else if requestOptions.sort.repliesCount?
        orderBy = "coalesce(content.repliesCount?, 0)"
      else
        orderBy = "content.`meta.createdAtEpoch`"

      queryOptions =
        userId     : requestOptions.originId
        to         : requestOptions.to
        # we have maximum call stack size error from bongo,
        # while sending the result back to client
        # this is a bandaid for it
        limitCount : 5 #requestOptions.limit
        skipCount  : requestOptions.skip

      query = QueryRegistry.activity.profilePage {facetQuery, orderBy}
      @fetchWithRelatedContent query, queryOptions, requestOptions, (err, res)->
        return callback err if err

        # This is a workaround to get over Neo4J skip-sort feature.
        # We are trimming items to return right resultset because Neo4J
        # returns an additional sticky item.

        # This doesn't happen when results are sorted by 'modifiedAt'.
        if "modifiedAt" of requestOptions.sort
          return callback err, res

        if res?.length > 1
          res = res[0..res.length-2]
        return callback err, res

  # this is following feed
  @fetchFolloweeContents:(options, callback)->
    # options should be as following format
    #{ userId: 52058e8ec9b66e3247000003,
    #  limit: 5,
    #  withExempt: false,
    #  facet: 'Everything',
    #  to: 1376274834525,
    #  client:
    #  { sessionToken: '811613c1d637f033babe288e4efa4fc6',
    #    context: { group: 'koding', user: 'siesta' },
    #    connection: { delegate: [Object] }
    #  }
    #}
    @getExemptUsersClauseIfNeeded options, (err, exemptClause)=>
      @getCurrentGroup options.client, (err, currentGroup)=>
        #generate options for queries
        queryOptions   = @generateOptions options, currentGroup
        requestOptions = @generateRequestOptions options.client, currentGroup

        #generate facet and time query if needed
        facet = @generateFacets options
        timeQuery = @generateTimeQuery options

        query = QueryRegistry.activity.following facet, timeQuery, exemptClause
        @fetchWithRelatedContent query, queryOptions, requestOptions, callback

  @fetchFolloweeContentsForNewKoding = (options={}, callback)->
    @getExemptUsersClauseIfNeeded options, (err, exemptClause)=>
      @getCurrentGroup options.client, (err, currentGroup)=>
        {limit, skip, client} = options
        {connection:{delegate}} = client

        queryOptions =
          limitCount : limit or 20
          skipCount  : skip or 0
          groupName  : currentGroup.slug or "koding"
          userId     : delegate.getId()

        timeQuery = @generateTimeQuery options
        query = QueryRegistry.activity.followingnew exemptClause, timeQuery
        @fetch query, queryOptions, (err, results) =>
          return callback err  if err
          callback err, results


  @fetchWithRelatedContent: (query, queryOptions, requestOptions, callback)->
    @fetch query, queryOptions, (err, results) =>
      if err
        console.log "err:", err
        return callback err
      if results? and results.length < 1 then return callback null, []
      resultData = (result.content.data for result in results)
      @objectify resultData, (objecteds)=>
        @getRelatedContent objecteds, requestOptions, callback

  # this function requires current group object and
  # user client object as option
  @getRelatedContent:(results, options, callback)->
    tempRes = []
    {group:{groupName, groupId}, client} = options
    collectRelations = race (i, res, fin)=>
      @fetchRelatedItems res, (err, relatedResult)=>
        clientRelations = reply: 'replies', tag: 'tags', opinion: 'opinions'
        if err
          console.log "errr", err
          fin()
          return callback err
        else
          # this works different on following feed and profile page
          tempRes[i][v] = [] for k, v of clientRelations
          for k of relatedResult
            clientRelName = clientRelations[k]
            if clientRelName?
              for bongoObj in relatedResult[k]
                tempRes[i][clientRelName].push bongoObj
              tempRes[i][clientRelName].reverse()
          fin()
    , =>
      if groupName == "koding" or not groupName?
        @removePrivateContent client, groupId, tempRes, (err, cleanContent)=>
          if err then return callback err
          callback null, cleanContent
      else
        callback null, tempRes

    @revive results, (reviveds)=>
      for revived in reviveds
        tempRes.push revived
        collectRelations revived

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

        if not resultData.length
          return callback null, resultData

      @objectify resultData, (objected)=>
        respond = {}
        @revive objected, (objects)->
          for obj in objects
            type = obj.data.relationType
            if not respond[type] then respond[type] = []
            respond[type].push obj
          callback err, respond

  @getSecretGroups: (client, callback)->
    JGroup = require '../group'
    JGroup.some
      $or: [
        { privacy: "private" }
        { visibility: "hidden" }
      ]
      slug:
        $nin: ["koding"] # we need koding even if its private
    , {}, (err, groups)=>
      return callback err if err
      return callback null, [] unless groups?
      return callback null, [] if groups.length < 1
      secretGroups = (group.slug for group in groups)
      callback null, secretGroups

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
