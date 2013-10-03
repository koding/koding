{Graph} = require './index'
QueryRegistry = require './queryregistry'

module.exports = class Invitation extends Graph

#  @fetchInvitations = (options, callback)->
#    {groupId, status, timestamp, requestLimit, search} = options
#
#    queryOptions =
#      groupId    : groupId
#      limitCount : requestLimit or 10
#
#    regexSearch    = ""
#    timeStampQuery = ""
#
#    if search
#      search = search.replace(/[^\w\s@.+-]/).trim()
#      regexSearch = "AND groupOwnedNodes.email =~ \".*#{search}.*\""
#
#    if timestamp?
#      timeStampQuery = "AND groupOwnedNodes.requestedAt > \"#{timestamp}\""
#
#    if typeof status is "string" then status = [status]
#
#    # convert status array into string representation
#    status   = "[\"" + status.join("\",\"") + "\"]"
#
#    query = QueryRegistry.invitation.list status, timeStampQuery, regexSearch
#
#    @fetch query, queryOptions, (err, results)=>
#      if err then return callback err
#      if results.length < 1 then return callback null, []
#      @generateInvitations [], results, (err, data)=>
#        if err then callback err
#        @revive data, (revived)->
#          callback null, revived
#
#  @generateInvitations:(resultData, results, callback)=>
#    if results? and results.length < 1 then return callback null, resultData
#    result = results.shift()
#    @objectify result.groupOwnedNodes.data, (objected)=>
#      resultData.push objected
#      @generateInvitations resultData, results, callback
#


  @getFetchOrCountInvitationsQuery = (method, options)->
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

  @fetchOrCountInvitationRequests:(method, options, callback)->
    options.model          = 'JInvitationRequest'
    options.timestampField = 'requestedAt'
    options.searchField    = 'email'
    options.query          = 'AND has(groupOwnedNodes.username)'

    query = @getFetchOrCountInvitationsQuery method, options
    @fetch query, {}, callback

  @fetchOrCountInvitations:(method, options, callback)->
    options.model          = 'JInvitation'
    options.timestampField = 'createdAt'
    options.searchField    = 'email'
    options.query          = "AND groupOwnedNodes.type = 'admin'"

    query = @getFetchOrCountInvitationsQuery method, options
    @fetch query, {}, callback

  @fetchOrCountInvitationCodes:(method, options, callback)->
    options.model          = 'JInvitation'
    options.timestampField = 'createdAt'
    options.searchField    = 'code'
    options.query          = "AND groupOwnedNodes.type = 'multiuse'"

    query = @getFetchOrCountInvitationsQuery method, options
    @fetch query, {}, callback
