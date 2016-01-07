KodingFluxStore = require 'app/flux/base/store'
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
   * It updates selected index for a given stateId
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @param {number} payload.index
   * @return {immutable.Map} nextState
  ###
  setIndex: (currentState, { stateId, index }) ->

    currentState.set stateId, index


  ###*
   * It increments selected index for a given stateId
   *
   * @param {object} payload
   * @param {string} payload.stateId
   * @return {immutable.Map} nextState
  ###
  moveToNextIndex: (currentState, { stateId }) ->

    index = currentState.get(stateId) ? 0
    currentState.set stateId, index + 1


  ###*
   * It decrements selected index for a given stateId
   *
   * @param {object} payload
   * @param {string} payload.stateId
   * @return {immutable.Map} nextState
  ###
  moveToPrevIndex: (currentState, { stateId }) ->

    index = currentState.get(stateId) ? 0
    currentState.set stateId, index - 1


  ###*
   * It deleted selected index for a given stateId
   *
   * @param {number} currentState
   * @param {string} payload.stateId
   * @return {number} nextState
  ###
  resetIndex: (currentState, { stateId }) ->

    currentState.delete stateId
