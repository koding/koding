KodingFluxStore = require 'app/flux/base/store'
actions        = require 'activity/flux/createchannel/actions/actiontypes'

###*
 * Store to handle participants-dropdown of create new channel modal search query
###
module.exports = class CreateNewChannelParticipantsSearchQueryStore extends KodingFluxStore

  @getterPath = 'CreateNewChannelParticipantsSearchQueryStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_QUERY,   @setQuery
    @on actions.UNSET_CREATE_NEW_CHANNEL_PARTICIPANTS_QUERY, @unsetQuery


  ###*
   * It sets current query with a given value
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
