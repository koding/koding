_              = require "underscore"
async          = require "async"
Graph          = require "./graph"
GraphDecorator = require "./graph_decorator"

module.exports =
  fetchAllActivityParallel: (startDate, neo4j, callback)->
    setStartDate startDate
    setNeo4j     neo4j

    async.parallel [fetchSingles], (err, results)->
      callback decorateAll(err, results)

getStartDate =-> @startDate or {}
getNeo4j     =-> @neo4j     or ""

setStartDate = (startDate)-> @startDate = startDate
setNeo4j     = (neo4j)    -> @neo4j     = neo4j

fetchSingles = (callback)->
  graph = new Graph getNeo4j()
  graph.fetchAll getStartDate(), (err, rawResponse)->
    GraphDecorator.decorateSingles rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchTagFollows = (callback)->
  graph = new Graph neo4j
  graph.fetchTagFollows getStartDate(), (err, rawResponse)->
    GraphDecorator.decorateFollows rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchMemberFollows = (callback)->
  graph = new Graph neo4j
  graph.fetchMemberFollows getStartDate(), (err, rawResponse)->
    GraphDecorator.decorateFollows rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchInstalls = (callback)->
  graph = new Graph neo4j
  graph.fetchNewInstalledApps getStartDate(), (err, rawResponse)->
    GraphDecorator.decorateInstalls rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchNewMembers = (callback)->
  graph = new Graph neo4j
  graph.fetchNewMembers getStartDate(), (err, rawResponse)->
    GraphDecorator.decorateMembers rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

randomIdToOriginal = {}
decorateAll = (err, decoratedObjects)->
  cacheObjects    = {}
  overviewObjects = []
  newMemberBucketIndex = null

  for objects in decoratedObjects
    for key, value of objects when key isnt "overview"
      randomId = generateUniqueRandomKey()
      randomIdToOriginal[key] = randomId
      value._id = randomId
      cacheObjects[randomId] = value

    for activity in objects.overview
      ids = []
      for originalId in activity.ids
        ids.push randomIdToOriginal[originalId]

      activity.ids = ids

    overviewObjects.push objects.overview

  overview = _.flatten(overviewObjects)

  return {}  if overview.length is 0

  overview = _.sortBy(overview, (activity)-> activity.createdAt.first)

  for activity, index in overview when activity.type is "CNewMemberBucketActivity"
    newMemberBucketIndex = index

  response            = {}
  response.activities = cacheObjects
  response.overview   = overview
  response._id        = "1"
  response.isFull     = true
  response.from       = overview.first.createdAt.last
  response.to         = overview.last.createdAt.first
  response.newMemberBucketIndex = newMemberBucketIndex  if newMemberBucketIndex

  return response

cachedIds = {}
generateUniqueRandomKey =->
  randomId = Math.floor(Math.random()*1000)
  if cachedIds[randomId]
    generateUniqueRandomKey()
  else
    cachedIds[randomId] = true
    return randomId
