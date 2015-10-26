KodingFluxStore = require 'app/flux/base/store'
immutable       = require 'immutable'

###*
 * Base class to store and manage list queries
###
module.exports = class ChatInputQueryStore extends KodingFluxStore

  getInitialState: -> immutable.Map()


  ###*
   * Descendant class should call this method
   * to bind action names to proper methods
   *
   * @param {object} actions
  ###
  bindActions: (actions) ->

    @on actions.setQuery,   @setQuery
    @on actions.unsetQuery, @unsetQuery


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

