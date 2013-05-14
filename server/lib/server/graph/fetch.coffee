_              = require "underscore"
async          = require "async"
Graph          = require "./graph"
GraphDecorator = require "./graph_decorator"

module.exports =
  fetchAllActivityParallel: (startDate, endDate, neo4j, callback)->
    setStartDate startDate
    setEndDate   endDate
    setNeo4j     neo4j

    async.parallel [fetchSingles], (err, results)->
      callback decorateAll(err, results)

getStartDate =-> @startDate or {}
getEndDate   =-> @endDate   or {}
getNeo4j     =-> @neo4j     or ""

setStartDate = (startDate)-> @startDate = startDate
setEndDate   = (endDate)  -> @endDate   = endDate
setNeo4j     = (neo4j)    -> @neo4j     = neo4j

fetchSingles = (callback)->
  graph = new Graph getNeo4j()
  graph.fetchAll getStartDate(), getEndDate(), (err, rawResponse)->
    GraphDecorator.decorateSingles rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchFollows = (callback)->
  graph = new Graph neo4j
  graph.fetchNewFollows getStartDate(), getEndDate(), (err, rawResponse)->
    GraphDecorator.decorateFollows rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchInstalls = (callback)->
  graph = new Graph neo4j
  graph.fetchNewInstalledApps getStartDate(), getEndDate(), (err, rawResponse)->
    GraphDecorator.decorateInstalls rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchMembers = (callback)->
  graph = new Graph neo4j
  graph.fetchNewMembers getStartDate(), getEndDate(), (err, rawResponse)->
    GraphDecorator.decorateMembers rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

decorateAll = (err, decoratedObjects)->
  cacheObjects    = {}
  overviewObjects = []
  newMemberBucketIndex = null

  for objects in decoratedObjects
    for key, value of objects when key isnt "overview"
      cacheObjects[key] = value
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
  response.isFull     = false
  response.from       = overview.first.createdAt.first
  response.to         = overview.last.createdAt.first
  response.newMemberBucketIndex = newMemberBucketIndex  if newMemberBucketIndex

  return response
