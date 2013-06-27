# TODO: refactor this ugliness

module.exports = class FetchAllActivityParallel
  _              = require "underscore"
  async          = require "async"
  Graph          = require "./graph"
  GraphDecorator = require "./graphdecorator"

  constructor:(@requestOptions)->
    {client, startDate, neo4j, group, facets} = @requestOptions

    @client               = client
    @graph                = new Graph {config : neo4j, facets: group.facets}
    @startDate            = startDate
    @group                = group
    @randomIdToOriginal   = {}
    @usedIds              = {}
    @cacheObjects         = {}
    @overviewObjects      = []
    @newMemberBucketIndex = null

    kodingMethods = [@fetchInstalls]
    if group.facets is 'Everything'
      @globalMethods = [@fetchSingles, @fetchTagFollows, @fetchNewMembers, @fetchMemberFollows]

      # HACK: we don't want to show app install in groups other than koding,
      #       but they're currently global, so we manually filter them out.
      if @group.groupName == "koding"
        @globalMethods = @globalMethods.concat kodingMethods
    else
      @globalMethods = [@fetchSingles]

  get:(callback)->
    holder = []
    boundMethods = holder.push method.bind this for method in @globalMethods
    async.parallel holder, (err, results)=>
      callback @decorateAll(err, results)

  fetchSingles:(callback)->
    @graph.fetchAll @requestOptions, (err, rawResponse=[])->
      GraphDecorator.decorateSingles rawResponse, (decoratedResponse)->
        callback err, decoratedResponse

  fetchTagFollows: (callback)->
    @graph.fetchTagFollows @group, @startDate, (err, rawResponse=[])->
      GraphDecorator.decorateFollows rawResponse, (decoratedResponse)->
        callback err, decoratedResponse

  fetchMemberFollows: (callback)->
    @graph.fetchMemberFollows @group, @startDate, (err, rawResponse=[])->
      GraphDecorator.decorateFollows rawResponse, (decoratedResponse)->
        callback err, decoratedResponse

  fetchInstalls: (callback)->
    @graph.fetchNewInstalledApps @group, @startDate, (err, rawResponse=[])->
      GraphDecorator.decorateInstalls rawResponse, (decoratedResponse)->
        callback err, decoratedResponse

  fetchNewMembers: (callback)->
    @graph.fetchNewMembers @group, @startDate, (err, rawResponse=[])->
      GraphDecorator.decorateMembers rawResponse, (decoratedResponse)->
        callback err, decoratedResponse

  bucketNames:->
    return {
      "CFollowerBucketActivity"  : true
      "CInstallerBucketActivity" : true
      "CNewMemberBucketActivity" : true
    }

  decorateAll: (err, decoratedObjects)->
    for objects in decoratedObjects
      for key, value of objects when key isnt "overview"
        randomId = @generateUniqueRandomKey()
        @randomIdToOriginal[key] = randomId
        value._id = randomId

        if @bucketNames()[value.type]
          oldSnapshot = JSON.parse(value.snapshot)
          oldSnapshot._id = randomId
          oldSnapshot.subscribeable = false
          value.snapshot = JSON.stringify oldSnapshot

        @cacheObjects[randomId] = value

      for activity in objects.overview
        ids = []
        for originalId in activity.ids
          ids.push @randomIdToOriginal[originalId]

        activity.ids = ids

      @overviewObjects.push objects.overview

    overview = _.flatten @overviewObjects

    return {}  if overview.length is 0

    overview = _.sortBy(overview, (activity)-> activity.createdAt.first)

    # TODO: we're throwing away results if more than 20, ideally we'll only
    # get the right number of results
    overview = overview[-20..overview.length]

    allTimes = _.map(overview, (activity)-> activity.createdAt.first)
    allTimes = _.flatten allTimes
    sortedAllTimes = _.sortBy(allTimes, (activity)-> activity)

    for activity, index in overview when activity.type is "CNewMemberBucketActivity"
      @newMemberBucketIndex = index

    return @decorateResponse overview, sortedAllTimes

  decorateResponse: (overview, sortedAllTimes)->
    response            = {}
    response.activities = @cacheObjects
    response.overview   = overview
    response._id        = "1"
    response.isFull     = true
    response.from       = sortedAllTimes.first
    response.to         = sortedAllTimes.last
    response.newMemberBucketIndex = @newMemberBucketIndex  if @newMemberBucketIndex

    return response

  generateUniqueRandomKey: ->
    randomId = Math.floor(Math.random()*100000)
    if @usedIds[randomId]
      @generateUniqueRandomKey()
    else
      @usedIds[randomId] = true
      return randomId
