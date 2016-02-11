actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'

###*
 * Store to handle emoji selectbox query
###
module.exports = class EmojiSelectBoxQueryStore extends KodingFluxStore

  @getterPath = 'EmojiSelectBoxQueryStore'

  initialize: ->

    @on actions.SET_EMOJI_SELECTBOX_QUERY,   @setQuery
    @on actions.UNSET_EMOJI_SELECTBOX_QUERY, @unsetQuery


  ###*
   * It updates query for a given stateId
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @param {string} payload.query
   * @return {immutable.Map} nextState
  ###
  setQuery: (currentState, { stateId, query }) ->

    currentState.set stateId, query


  ###*
   * It deletes query for a given stateId
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @return {immutable.Map} nextState
  ###
  unsetQuery: (currentState, { stateId }) ->

    currentState.delete stateId
