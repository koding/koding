KodingFluxStore = require 'app/flux/store'

###*
 * Base class to store and manage a query of list
###
module.exports = class ChatInputQueryStore extends KodingFluxStore

  getInitialState: -> null


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
