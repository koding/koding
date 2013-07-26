{Graph} = require './index'
QueryRegistry = require './queryregistry'

module.exports = class Member extends Graph

  @getOrderByQuery:(orderBy)->
    switch orderBy
      when "counts.followers"
        orderByQuery = "members.`counts.followers`"
      when "counts.following"
        orderByQuery = "members.`counts.following`"
      when "meta.modifiedAt"
        orderByQuery = "members.`meta.modifiedAt`"
      else
        orderByQuery = "members.`counts.followers`"

    return orderByQuery

  @generateOptions:(options)->
    {skip, limit, sort, groupId, currentUserId, startDate} = options

    orderBy = if sort? then Object.keys(sort)[0] else ""

    options =
      limitCount: limit or 10
      skipCount: skip or 0
      groupId: groupId
      currentUserId: "#{currentUserId}"
      orderByQuery: @getOrderByQuery orderBy
      to : startDate

  @fetchFollowingMembers:(options, callback)=>
    options = @generateOptions options
    query = QueryRegistry.member.following
    @queryMembers query, options, callback


  @fetchFollowerMembers:(options, callback)=>
    options = @generateOptions options
    query = QueryRegistry.member.follower
    @queryMembers query, options, callback


  @searchMembers:(options, callback)->
    {groupId, seed, firstNameRegExp, lastNameRegexp, skip, limit, blacklist} = options
    activity = require './activity'
    activity.getCurrentGroup options.client, (err, group)=>
      if err
        return callback err

      queryOptions = 
        blacklistQuery: ""
        skip: skip or 0
        limitCount: limit or 10
        seed: seed
        firstNameRegExp: firstNameRegExp
        lastNameRegexp: lastNameRegexp

      options.groupId = group.getId()

      if blacklist? and blacklist.length
        blacklistIds = ("'#{id}'" for id in blacklist).join(',')
        queryOptions.blacklistQuery = " AND NOT( members.id IN [#{ blacklistIds }] )"

      @getExemptUsersClauseIfNeeded options, (err, exemptClause)=>
        queryOptions.exemptClause = exemptClause
        query = QueryRegistry.member.search queryOptions
        @queryMembers query, options, callback

  @fetchMemberList:(options, callback)->
    # {groupId, to} = options
    # console.log "undefined request parameter" unless groupId and to
    @getExemptUsersClauseIfNeeded options, (err, exemptClause)=>
      options = @generateOptions options
      query = QueryRegistry.member.list exemptClause
      @queryMembers query, options, callback

  @queryMembers:(query, options={}, callback)=>
    @fetch query, options, (err, results) =>
      if err then return callback err
      if results? and results.length < 1 then return callback null, []
      resultData = []
      @generateMembers [], results, (err, data)=>
        if err then callback err
        @revive data, (revived)->
          callback null, revived

  @generateMembers:(resultData, results, callback)=>
    if results? and results.length < 1 then return callback null, resultData
    result = results.shift()

    results.map (result)->
      result["members"]
    @objectify result.members.data, (objected)=>
      resultData.push objected
      @generateMembers resultData, results, callback

  @fetchMemberCount:(options, callback)=>
    @getExemptUsersClauseIfNeeded options, (err, exemptClause)=>
      query = QueryRegistry.member.count exemptClause
      @fetch query, options, (err, results) =>
        if err then return callback err
        callback null, results[0].count
