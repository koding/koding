KodingFluxStore = require 'app/flux/store'
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
   * It updates query for a given action initiator
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.initiatorId
   * @param {string} payload.query
   * @return {immutable.Map} nextState
  ###
  setQuery: (currentState, { initiatorId, query }) ->

    currentState.set initiatorId, query


  ###*
   * It deletes query for a given action initiator
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.initiatorId
   * @return {immutable.Map} nextState
  ###
  unsetQuery: (currentState, { initiatorId }) ->

    currentState.delete initiatorId

