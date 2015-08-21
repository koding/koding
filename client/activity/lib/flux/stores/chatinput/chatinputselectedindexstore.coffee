KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Base class to store and manage selected index of list
###
module.exports = class ChatInputSelectedIndexStore extends KodingFluxStore

  getInitialState: -> 0


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
   * It updates current selected index with a given value
   *
   * @param {number} currentState
   * @param {object} payload
   * @param {number} payload.index
   * @return {number} nextState
  ###
  setIndex: (currentState, { index }) -> index


  ###*
   * It increments current selected index
   *
   * @param {number} currentState
   * @return {number} nextState
  ###
  moveToNextIndex: (currentState) -> currentState + 1


  ###*
   * It decrements current selected index
   *
   * @param {number} currentState
   * @return {number} nextState
  ###
  moveToPrevIndex: (currentState) -> currentState - 1


  ###*
   * It resets current selected index to initial value
   *
   * @param {number} currentState
   * @return {number} nextState
  ###
  resetIndex: (currentState) -> 0
