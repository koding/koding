KodingFluxStore = require 'app/flux/base/store'
actions = require '../actiontypes'
immutable = require 'immutable'
toImmutable = require 'app/util/toImmutable'


module.exports = class TeamAPITokensStore extends KodingFluxStore

  @getterPath = 'TeamAPITokensStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.FETCH_API_TOKENS_SUCCESS, @load
    @on actions.DELETE_API_TOKEN_SUCCESS, @delete
    @on actions.ADD_API_TOKEN_SUCCESS, @add

  load: (apiTokenIds, { apiTokens }) ->

    apiTokenIds.withMutations (apiTokenIds) ->
      apiTokens.forEach (apiToken) ->
        apiTokenIds.set apiToken._id, toImmutable apiToken

  delete: (apiTokenIds, { apiTokenId }) ->

    apiTokenIds.delete apiTokenId

  add: (apiTokenIds, { apiToken }) ->

    apiTokenIds.set apiToken._id, toImmutable apiToken
