actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

###*
 * Store to contain filtered emoji list query
###
module.exports = class FilteredEmojiListQueryStore extends KodingFluxStore

  @getterPath = 'FilteredEmojiListQueryStore'

  getInitialState: -> null


  initialize: ->

    @on actions.SET_FILTERED_EMOJI_LIST_QUERY,   @setQuery
    @on actions.UNSET_FILTERED_EMOJI_LIST_QUERY, @unsetQuery


  ###*
   * Handler of SET_FILTERED_EMOJI_LIST_QUERY action
   * It updates current query with a given value
   *
   * @param {string} currentState
   * @param {object} payload
   * @param {string} payload.query
   * @return {string} nextState
  ###
  setQuery: (currentState, { query }) -> query


  ###*
   * Handler of UNSET_FILTERED_EMOJI_LIST_QUERY action
   * It resets current query to initial value
   *
   * @param {string} currentState
   * @return {string} nextState
  ###
  unsetQuery: (currentState) -> null
