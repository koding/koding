actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'

###*
 * Store to contain suggestions selected index
###
module.exports = class SuggestionsSelectedIndexStore extends KodingFluxStore

  @getterPath = 'SuggestionsSelectedIndexStore'

  getInitialState: -> 0


  initialize: ->

    @on actions.SET_SUGGESTIONS_SELECTED_INDEX,   @setIndex
    @on actions.RESET_SUGGESTIONS_SELECTED_INDEX, @resetIndex
    @on actions.MOVE_TO_NEXT_SUGGESTIONS_INDEX,   @moveToNextIndex
    @on actions.MOVE_TO_PREV_SUGGESTIONS_INDEX,   @moveToPrevIndex


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

