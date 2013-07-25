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

      # console.log "-----------------------"
      # console.log query
      # console.log "// --------------------"

      @fetch query, options, (err, results) =>
        if err
          return callback err
        if results? and results.length < 1 then return callback null, []
        resultData = (result.members.data for result in results)
        @objectify resultData, (objecteds)=>
          @revive objecteds, (objects)->
            callback err, objects

      
      # @db.query query, {}, (err, results) =>
      #   if err
      #     console.log "ERR:", err
      #     return callback err
      #   else if results.length is 0 then callback null, []
      #   else
      #     objectify results[0].members.data, (objected)=>
      #       console.log "objected ? !!!!", objected
      #       {collections, wantedOrder} = @getIdsFromAResultSet [objected]
      #       @fetchObjectsFromMongo collections, wantedOrder, (err, dbObjects)->
      #         callback err, dbObjects

  @fetchMemberList:(options, callback)->
    # {groupId, to} = options
    # console.log "undefined request parameter" unless groupId and to
    options = @generateOptions options
    query = QueryRegistry.member.list
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


  @fetchRelationshipCount:(options, callback)=>
    {groupId, relName} = options
    query = """
      START group=node:koding("id:#{groupId}")
      match group-[:#{relName}]->items
      return count(items) as count
    """
    @fetch query, {}, (err, results) =>
      if err then callback err, null
      else callback null, results[0].count
