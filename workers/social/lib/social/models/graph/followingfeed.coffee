{Graph} = require './index'
QueryRegistry = require './queryregistry'
{race} = require "bongo"
module.exports = class Member extends Graph

  @fetchAll:(requestOptions, callback)->
    {group:{groupName, groupId}, startDate, client, facet} = requestOptions

    options =
      groupId : groupId
      to  : startDate
      limitCount : 20

    facetQuery = groupFilter = ""

    #generate facet query line and add its option
    if facet and facet isnt "Everything"
      options.facet = facet
      facetQuery += "AND content.name = {facet}"

    #generate groupName filter and add its paramter to options
    if groupName isnt "koding"
      options.groupName = groupName
      groupFilter = "AND content.group! = {groupName}"

    query = QueryRegistry.activity.public facetQuery, groupFilter

    @fetch query, options, (err, results) =>
      if err then return callback err
      if results? and results.length < 1 then return callback null, []
      resultData = (result.content.data for result in results)
      @objectify resultData, (objecteds)=>
        @getRelatedContent objecteds, requestOptions, callback

  @getRelatedContent:(results, options, callback)->
    tempRes = []
    {group:{groupName, groupId}, client} = options

    collectRelations = race (i, res, fin)=>
      id = res.id

      @fetchRelatedItems id, (err, relatedResult)=>
        if err
          return callback err
          fin()
        else
          tempRes[i].relationData =  relatedResult
          fin()
    , =>
      if groupName == "koding"
        @removePrivateContent client, groupId, tempRes, callback
      else
        callback null, tempRes

    for result in results
      tempRes.push result
      collectRelations result

  @fetchRelatedItems: (itemId, callback)->
    query = """
      start koding=node:koding("id:#{itemId}")
      match koding-[r]-all
      return all, r
      order by r.createdAtEpoch DESC
      """
    @fetchRelateds query, callback

  @fetchRelateds:(query, callback)->
    @fetch query, {}, (err, results) =>
      if err then callback err
      resultData = []
      for result in results
        type = result.r.type
        data = result.all.data
        data.relationType = type
        resultData.push data

      @objectify resultData, (objected)->
        respond = {}
        for obj in objected
          type = obj.relationType
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
