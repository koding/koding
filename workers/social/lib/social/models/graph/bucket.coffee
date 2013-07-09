neo4j = require "neo4j"

{Graph} = require './index'
QueryRegistry = require './queryregistry'

module.exports = class Bucket extends Graph

  @fetchNewMembers:(group, to, callback)->
    {groupName, groupId} = group
    options =
      groupId : groupId
      to      : to

    query = QueryRegistry.bucket.newMembers
    @queryMembers query, options, callback

  # fetchNewMembers:(group, startDate, callback)->
  #   console.time 'fetchNewMembers'

  #   {groupId} = group

  #   query = """
  #     start  koding=node:koding("id:#{groupId}")
  #     MATCH  koding-[r:member]->members
  #     where  r.createdAtEpoch < #{startDate}
  #     return members
  #     order by r.createdAtEpoch DESC
  #     limit 20
  #     """
  #   @db.query query, {}, (err, results) ->
  #       if err then throw err
  #       resultData = []
  #       for result in results
  #         data = result.members.data
  #         resultData.push data

  #       objectify resultData, (objected)->
  #         callback err, objected

  #         console.timeEnd 'fetchNewMembers'

  @queryMembers:(query, options={}, callback)->
    @fetch query, options, (err, results) =>
      if err then return callback err
      if results? and results.length < 1 then return callback null, []
      resultData = []
      @generateMembers [], results, (err, data)=>
        if err then return callback err
        @revive data, (revived)->
          console.log revived
          callback null, revived

  @generateMembers:(resultData, results, callback)->
    if results? and results.length < 1 then return callback null, resultData
    result = results.shift()
    @objectify result.members.data, (objected)=>
      resultData.push objected
      @generateMembers resultData, results, callback

  ###############################################
  ########## new installed apps  ################
  ###############################################
  @fetchNewInstalledApps:(group, to, callback)->
    {groupName, groupId} = group
    options =
      groupId : groupId
      to      : to

    query = QueryRegistry.bucket.newInstallations

    @fetch query, options, (err, results) =>
      if err then throw err
      @generateInstalledApps [], results, callback

  @generateInstalledApps:(resultData, results, callback)->
    if results? and results.length < 1 then return callback null, resultData
    result = results.shift()
    data = {}
    @objectify result.users.data, (objected)=>
      data.user = objected
      @objectify result.r.data, (objected)=>
        data.relationship = objected
        @objectify result.apps.data, (objected)=>
          data.app = objected
          resultData.push data
          @generateInstalledApps resultData, results, callback



  ###############################################
  ########## new member follows  ################
  ###############################################
  @fetchMemberFollows:(group, to, callback)->
    {groupId} = group
    options =
      groupId : groupId
      to      : to
    query = QueryRegistry.bucket.newUserFollows
    @fetchFollows query, options, callback


  ###############################################
  ############# new tag follows  ################
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
