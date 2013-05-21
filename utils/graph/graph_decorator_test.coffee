GraphDecorator = require '../../server/lib/server/graph/graph_decorator'
async          = require 'async'
_              = require 'underscore'
FetchAllActivityParallel = require '../../server/lib/server/graph/fetch'

fetchSingles = (callback)->
  rawResponse = require('fs').readFileSync './fixtures/single_activities.sample', 'utf8'
  rawResponse = JSON.parse rawResponse
  GraphDecorator.decorateSingles rawResponse, (decoratedResponse)->
    callback null, decoratedResponse

fetchMemberFollows = (callback)->
  rawResponse = require('fs').readFileSync './member_follows_bucket.sample', 'utf8'
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

async.parallel [fetchMemberFollows], (err, results)->
  f = new FetchAllActivityParallel Date.now(), {}
  console.log JSON.stringify(f.decorateAll(err, results), null, 3)
