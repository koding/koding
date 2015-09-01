KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

###*
 * Base class to store and manage list selected indexes
###
module.exports = class ChatInputSelectedIndexStore extends KodingFluxStore

  getInitialState: -> immutable.Map()


  ###*
   * Descendant class should call this method
   * to bind action names to proper methods
   *
   * @param {object} actions
  ###
  bindActions: (actions) ->

    @on actions.setIndex,        @setIndex
    @on actions.resetIndex,      @resetIndex
    @on actions.moveToNextIndex, @moveToNextIndex  if actions.moveToNextIndex
    @on actions.moveToPrevIndex, @moveToPrevIndex  if actions.moveToPrevIndex


  ###*
   * It updates selected index for a given action initiator
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.initiatorId
   * @param {number} payload.index
   * @return {immutable.Map} nextState
  ###
  setIndex: (currentState, { initiatorId, index }) ->

    currentState.set initiatorId, index


  ###*
   * It increments selected index for a given action initiator
   *
   * @param {object} payload
   * @param {string} payload.initiatorId
   * @return {immutable.Map} nextState
  ###
  moveToNextIndex: (currentState, { initiatorId }) ->

    index = currentState.get(initiatorId) ? 0
    currentState.set initiatorId, index + 1


  ###*
   * It decrements selected index for a given action initiator
   *
   * @param {object} payload
   * @param {string} payload.initiatorId
   * @return {immutable.Map} nextState
  ###
  moveToPrevIndex: (currentState, { initiatorId }) ->

    index = currentState.get(initiatorId) ? 0
    currentState.set initiatorId, index - 1


  ###*
   * It deleted selected index for a given action initiator
   *
   * @param {number} currentState
   * @param {string} payload.initiatorId
   * @return {number} nextState
  ###
  resetIndex: (currentState, { initiatorId }) ->

    currentState.delete initiatorId

