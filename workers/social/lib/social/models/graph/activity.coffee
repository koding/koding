neo4j = require "neo4j"

{Graph} = require './index'
QueryRegistry = require './queryregistry'

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
        facetQueryList.push("items.name='#{facet}'")
      facetQuery = "AND (" + facetQueryList.join(' OR ') + ")"
    # add timestamp

    return facetQuery

  # generate options
  @generateOptions:(options)->
    {limit, groupId, userId, facets, to} = options
    orderBy = if sort? then Object.keys(sort)[0] else ""
    options =
      limitCount: limit or 10
      groupName : groupName
      userId    : "#{userId}"
      timeQuery : timeQuery
      facet     : facet


  ###############################################
  ########### followee content   ################
  ###############################################
  @fetchFolloweeContents:(options, callback)->
    options = @generateOptions options
    query = QueryRegistry.bucket.newUserFollows
    @fetchFollows query, options, callback


  ###############################################
  ############# follower content  ###############
  ###############################################
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
