{Graph} = require './index'
QueryRegistry = require './queryregistry'

module.exports = class Invitation extends Graph

  @fetchInvitations = (options, callback)->
    {groupId, status, timestamp, requestLimit, search} = options

    queryOptions =
      groupId    : groupId
      limitCount : requestLimit or 10

    regexSearch    = ""
    timeStampQuery = ""

    if search
      search = search.replace(/[^\w\s@.+-]/).trim()
      regexSearch = "AND groupOwnedNodes.email =~ \".*#{search}.*\""

    if timestamp?
      timeStampQuery = "AND groupOwnedNodes.requestedAt > \"#{timestamp}\""

    if typeof status is "string" then status = [status]

    # convert status array into string representation
    status   = "[\"" + status.join("\",\"") + "\"]"

    query = QueryRegistry.invitation.list status, timeStampQuery, regexSearch

    @fetch query, queryOptions, (err, results)=>
      console.log "arguments"
      console.log arguments
      if err then return callback err
      if results.length < 1 then return callback null, []
      @generateInvitations [], results, (err, data)=>
        console.log "err.data"
        console.log err, data
        if err then callback err
        @revive data, (revived)->
          console.log "revived"
          console.log revived
          callback null, revived

  @generateInvitations:(resultData, results, callback)=>
    console.log "generate inviations arguments"
    console.log arguments
    if results? and results.length < 1 then return callback null, resultData
    result = results.shift()
    console.log "result"
    console.log result
    @objectify result.groupOwnedNodes.data, (objected)=>
      console.log "objected"
      console.log objected
      resultData.push objected
      @generateInvitations resultData, results, callback


