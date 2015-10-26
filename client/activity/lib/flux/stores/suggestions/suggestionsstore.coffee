kd              = require 'kd'
immutable       = require 'immutable'
actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to contain a list of suggestions
 * It listens for FETCH_SUGGESTIONS_SUCCESS,
 * FETCH_SUGGESTIONS_FAIL and SUGGESTIONS_DATA_RESET actions
 * to update stored list
###
module.exports = class SuggestionsStore extends KodingFluxStore

  @getterPath = 'SuggestionsStore'

  getInitialState: -> immutable.List()


  initialize: ->

    @on actions.FETCH_SUGGESTIONS_SUCCESS, @handleFetchSuccess
    @on actions.FETCH_SUGGESTIONS_FAIL, @handleFetchFail
    @on actions.SUGGESTIONS_DATA_RESET, @handleReset


  ###*
   * Handler for FETCH_SUGGESTIONS_SUCCESS action.
   * It sets current results to successfully fetched
   * new data
   *
   * @param {Immutable.List} results
   * @param {object} payload
   * @param {array} payload.data
   * @return {Immutable.List} new data
  ###
  handleFetchSuccess: (results, { data }) -> toImmutable data


  ###*
   * Handler for FETCH_SUGGESTIONS_FAIL action.
   * It resets current results if new data has failed
   * to load
   *
   * @param {Immutable.List} results
   * @return {Immutable.List} empty immutable list
  ###
  handleFetchFail: (results) -> @handleReset results


  ###*
   * Handler for SUGGESTIONS_DATA_RESET action.
   * It sets current results to empty immutable list
   *
   * @param {Immutable.List} results
   * @return {Immutable.List} empty immutable list
  ###
  handleReset: (results) -> immutable.List()

