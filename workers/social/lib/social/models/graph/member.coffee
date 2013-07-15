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


  @fetchMemberList:(options, callback)->
    # {groupId, to} = options
    # console.log "undefined request parameter" unless groupId and to
    console.log options
    options = @generateOptions options

    query = QueryRegistry.member.list
    @queryMembers query, options, callback

  @queryMembers:(query, options={}, callback)=>

    console.log "query members"
    console.log query
    console.log "options"
    console.log options

    @fetch query, options, (err, results) =>
      if err then return callback err
      if results? and results.length < 1 then return callback null, []
      resultData = []
      @generateMembers [], results, (err, data)=>
        if err then callback err
        @revive data, (revived)->
          console.log "revived"
          console.log revived
          callback null, revived

  @generateMembers:(resultData, results, callback)=>
    if results? and results.length < 1 then return callback null, resultData
    result = results.shift()

    results.map (result)->
      result["members"]
    @objectify result.members.data, (objected)=>
      resultData.push objected
      @generateMembers resultData, results, callback


