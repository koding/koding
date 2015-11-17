KodingFluxStore = require 'app/flux/base/store'
actions         = require 'activity/flux/actions/actiontypes'

###*
 * Base class to store and manage channel participants search queries
###
module.exports = class ChannelParticipantsSearchQueryStore extends KodingFluxStore

  @getterPath = 'ChannelParticipantsSearchQueryStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_CHANNEL_PARTICIPANTS_QUERY,   @setQuery
    @on actions.UNSET_CHANNEL_PARTICIPANTS_QUERY, @unsetQuery


  ###*
   * It updates current query with a given value
   *
   * @param {string} currentState
   * @param {object} payload
   * @param {string} payload.query
   * @return {string} nextState
  ###
  setQuery: (currentState, { query }) -> query


  ###*
   * It resets current query to initial value
   *
   * @param {string} currentState
   * @return {string} nextState
  ###
  unsetQuery: (currentState) -> null
