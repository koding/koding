GraphDecorator = require '../../server/lib/server/graph/graph_decorator'
async          = require 'async'
_              = require 'underscore'

fetchSingles = (callback)->
  _fetchSingles (err, rawResponse)->
    GraphDecorator.decorateSingles rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchFollows = (callback)->
  _fetchFollows (err, rawResponse)->
    GraphDecorator.decorateFollows rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchInstalls = (callback)->
  _fetchInstalls (err, rawResponse)->
    GraphDecorator.decorateInstalls rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

fetchMembers = (callback)->
  _fetchMembers (err, rawResponse)->
    GraphDecorator.decorateMembers rawResponse, (decoratedResponse)->
      callback err, decoratedResponse

_fetchSingles = (callback)->
  rawResponse = require('fs').readFileSync './fixtures/single_activities.sample', 'utf8'
  rawResponse = JSON.parse rawResponse
  callback null, rawResponse

_fetchInstalls = (callback)->
  rawResponse = require('fs').readFileSync './fixtures/installs_bucket.sample', 'utf8'
  rawResponse = JSON.parse rawResponse
  callback null, rawResponse

_fetchFollows = (callback)->
  rawResponse = require('fs').readFileSync './fixtures/follows_bucket.sample', 'utf8'
  rawResponse = JSON.parse rawResponse
  callback null, rawResponse

_fetchMembers = (callback)->
  rawResponse = require('fs').readFileSync './fixtures/members_bucket.sample', 'utf8'
  rawResponse = JSON.parse rawResponse
  callback null, rawResponse

#fetchSingles (err, decoratedResponse)->
  #console.log JSON.stringify(decoratedResponse, null, 3)

#fetchInstalls (err, decoratedResponse)->
  #console.log JSON.stringify(decoratedResponse, null, 3)

#fetchFollows (err, decoratedResponse)->
  #console.log JSON.stringify(decoratedResponse, null, 3)

fetchMembers (err, decoratedResponse)->
  console.log JSON.stringify(decoratedResponse, null, 3)

#decorateAll = (err, decoratedObjects)->
  #cacheObjects    = {}
  #overviewObjects = []

  #for objects in decoratedObjects
    #for key, value of objects when key isnt "overview"
      #cacheObjects[key] = value
    #overviewObjects.push objects.overview

  #overview = _.flatten overviewObjects
  #cacheObjects.overview = overview

  #return cacheObjects

#async.parallel [fetchSingles, fetchFollows], (err, results)->
  #console.log decorateAll(err, results)
