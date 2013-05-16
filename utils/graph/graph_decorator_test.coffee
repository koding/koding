GraphDecorator = require '../../server/lib/server/graph/graph_decorator'
async          = require 'async'
_              = require 'underscore'
{decorateAll, generateUniqueRandomKey}  = require '../../server/lib/server/graph/fetch'

fetchSingles = (callback)->
  rawResponse = require('fs').readFileSync './fixtures/single_activities.sample', 'utf8'
  rawResponse = JSON.parse rawResponse
  GraphDecorator.decorateSingles rawResponse, (decoratedResponse)->
    callback null, decoratedResponse

fetchMemberFollows = (callback)->
  rawResponse = require('fs').readFileSync './fixtures/member_follows_bucket.sample', 'utf8'
  rawResponse = JSON.parse rawResponse
  GraphDecorator.decorateFollows rawResponse, (decoratedResponse)->
    callback null, decoratedResponse

fetchTagFollows = (callback)->
  rawResponse = require('fs').readFileSync './fixtures/tag_follows_bucket.sample', 'utf8'
  rawResponse = JSON.parse rawResponse
  GraphDecorator.decorateFollows rawResponse, (decoratedResponse)->
    callback null, decoratedResponse

fetchInstalls = (callback)->
  rawResponse = require('fs').readFileSync './fixtures/installs_bucket.sample', 'utf8'
  rawResponse = JSON.parse rawResponse
  GraphDecorator.decorateInstalls rawResponse, (decoratedResponse)->
    callback null, decoratedResponse

fetchMembers = (callback)->
  rawResponse = require('fs').readFileSync './fixtures/members_bucket.sample', 'utf8'
  rawResponse = JSON.parse rawResponse
  GraphDecorator.decorateMembers rawResponse, (decoratedResponse)->
    callback null, decoratedResponse

randomIdToOriginal = {}
decorateAll = (err, decoratedObjects)->
  cacheObjects    = {}
  overviewObjects = []
  newMemberBucketIndex = null

  for objects in decoratedObjects
    for key, value of objects when key isnt "overview"
      randomId = generateUniqueRandomKey()
      randomIdToOriginal[key] = randomId
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
    console.log randomId, "already in", cachedIds
    generateUniqueRandomKey()
  else
    cachedIds[randomId] = true
    return randomId

async.parallel [fetchMembers], (err, results)->
  console.log JSON.stringify(decorateAll(err, results), null, 3)
