actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to contain filtered emoji list selected index
###
module.exports = class FilteredEmojiListSelectedIndexStore extends KodingFluxStore

  @getterPath = 'FilteredEmojiListSelectedIndexStore'

  getInitialState: -> 0


  initialize: ->

    @on actions.SET_FILTERED_EMOJI_LIST_SELECTED_INDEX,   @setIndex
    @on actions.MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX,   @moveToNextIndex
    @on actions.MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX,   @moveToPrevIndex
    @on actions.RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX, @resetIndex


  ###*
   * Handler of SET_FILTERED_EMOJI_LIST_SELECTED_INDEX action
   * It updates current selected index with a given value
   *
   * @param {number} currentState
   * @param {object} payload
   * @param {number} payload.index
   * @return {number} nextState
  ###
  setIndex: (currentState, { index }) -> index


  ###*
   * Handler of MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX action
   * It increments current selected index
   *
   * @param {number} currentState
   * @return {number} nextState
  ###
  moveToNextIndex: (currentState) -> currentState + 1


  ###*
   * Handler of MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX action
   * It decrements current selected index
   *
   * @param {number} currentState
   * @return {number} nextState
  ###
  moveToPrevIndex: (currentState) -> currentState - 1


  ###*
   * Handler of RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX action
   * It resets current selected index to initial value
   *
   * @param {number} currentState
   * @return {number} nextState
  ###
  resetIndex: (currentState) -> 0