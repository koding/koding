kd              = require 'kd'
actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

module.exports = class SuggestionsStore extends KodingFluxStore

  @getterPath = 'SuggestionsStore'

  getInitialState: -> toImmutable {}


  initialize: ->

    @on actions.FETCH_SUGGESTIONS_SUCCESS, @handleFetchSuccess
    @on actions.FETCH_SUGGESTIONS_FAIL, @handleFetchFail
    @on actions.SUGGESTIONS_DATA_RESET, @handleReset


  handleFetchSuccess: (results, { data }) ->

    results = toImmutable data


  handleFetchFail: (results) -> @handleReset results


  handleReset: (results) -> results = toImmutable []