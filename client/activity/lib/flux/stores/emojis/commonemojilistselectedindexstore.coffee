actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

###*
 * Store to contain common emoji list selected index
###
module.exports = class CommonEmojiListSelectedIndexStore extends KodingFluxStore

  @getterPath = 'CommonEmojiListSelectedIndexStore'

  getInitialState: -> 0


  initialize: ->

    @on actions.SET_COMMON_EMOJI_LIST_SELECTED_INDEX, @setIndex
    @on actions.RESET_COMMON_EMOJI_LIST_SELECTED_INDEX, @resetIndex


  ###*
   * Handler of SET_COMMON_EMOJI_LIST_SELECTED_INDEX action
   * It updates current selected index with a given value
   *
   * @param {number} currentState
   * @param {object} payload
   * @param {number} payload.index
   * @return {number} nextState
  ###
  setIndex: (currentState, { index }) -> index


  ###*
   * Handler of RESET_COMMON_EMOJI_LIST_SELECTED_INDEX action
   * It resets current selected index to initial value
   *
   * @param {number} currentState
   * @return {number} nextState
  ###
  resetIndex: (currentState) -> 0
