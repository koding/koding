{Graph} = require './index'
QueryRegistry = require './queryregistry'

module.exports = class Member extends Graph

  @getOrderByQuery: (options)->
    {sort} = options
    orderBy = if sort? then Object.keys(sort)[0] else ""

    switch orderBy
      when "counts.followers"
        orderByQuery = "ORDER BY members.`counts.followers` DESC"
      when "counts.following"
        orderByQuery = "ORDER BY members.`counts.following` DESC"
      when "meta.modifiedAt"
        orderByQuery = "ORDER BY members.`meta.modifiedAt` DESC"
      else
        orderByQuery = "ORDER BY members.`meta.modifiedAt` DESC"

    return orderByQuery

  @generateOptions: (options)->
    {client, skip, limit, sort, groupId, startDate} = options

    currentUserId = client.connection.delegate.getId()
    options =
      limitCount: limit or 10
      skipCount: skip or 0
      groupId: "#{groupId}"
      currentUserId: "#{currentUserId}"
      to: startDate

  # fetch members that are in given group who follows current user
  @fetchFollowingMembers: (options, callback)=>
    queryOptions = @generateOptions options
    orderByQuery = @getOrderByQuery options
    query = QueryRegistry.member.following orderByQuery
    @queryMembers query, queryOptions, callback

  # fetch member's following count
  @fetchFollowingMemberCount: (options, callback)=>
    queryOptions = @generateOptions options
    query = QueryRegistry.member.following
    @queryMembers query, queryOptions, callback

  # fetch members that are in given group who are followed by current user
  @fetchFollowerMembers: (options, callback)=>
    queryOptions = @generateOptions options
    orderByQuery = @getOrderByQuery options
    query = QueryRegistry.member.follower orderByQuery
    @queryMembers query, queryOptions, callback

  @searchMembers: (options, callback)->
    {groupId, seed, firstNameRegExp, lastNameRegexp, skip, limit, blacklist} = options
    activity = require './activity'
    activity.getCurrentGroup options.client, (err, group)=>
      if err then return callback err

      queryOptions =
        blacklistQuery: ""

        seed: seed
        firstNameRegExp: firstNameRegExp
        lastNameRegexp: lastNameRegexp

      options.groupId = "#{group.getId()}"
      options.skipCount = skip or 0
      options.limitCount = limit or 10

      if blacklist? and blacklist.length
        blacklistIds = ("'#{id}'" for id in blacklist).join(',')
        queryOptions.blacklistQuery = " AND NOT( members.id IN [#{ blacklistIds }] )"

      @getExemptUsersClauseIfNeeded options, (err, exemptClause)=>
        queryOptions.exemptClause = exemptClause
        query = QueryRegistry.member.search queryOptions
        @queryMembers query, options, callback

  @fetchMemberList: (options, callback)->
    # {groupId, to} = options
    # console.log "undefined request parameter" unless groupId and to
    @getExemptUsersClauseIfNeeded options, (err, exemptClause)=>
      queryOptions = @generateOptions options
      orderByQuery = @getOrderByQuery options
      query = QueryRegistry.member.list exemptClause, orderByQuery
      @queryMembers query, queryOptions, callback

  @queryMembers: (query, options = {}, callback)=>
    @fetch query, options, (err, results) =>
      if err then return callback err
      if results? and results.length < 1 then return callback null, []
      @generateMembers [], results, (err, data)=>
        if err then callback err
        @revive data, (revived)->
          callback null, revived

  @generateMembers: (resultData, results, callback)=>
    if results? and results.length < 1 then return callback null, resultData
    result = results.shift()
    @objectify result.members.data, (objected)=>
      resultData.push objected
      @generateMembers resultData, results, callback

  # fetchs member count in a group
  @fetchMemberCount: (options, callback)=>
    @getExemptUsersClauseIfNeeded options, (err, exemptClause)=>
      query = QueryRegistry.member.count exemptClause
      queryOptions = {groupId: options.groupId}
      @fetch query, queryOptions, (err, results) =>
        if err then return callback err
        callback null, results[0].count
