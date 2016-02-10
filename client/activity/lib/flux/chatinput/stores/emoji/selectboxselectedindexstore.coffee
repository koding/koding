actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'

###*
 * Store to contain emoji selectbox selected index
###
module.exports = class EmojiSelectBoxSelectedIndexStore extends KodingFluxStore

  @getterPath = 'EmojiSelectBoxSelectedIndexStore'

  initialize: ->

    @on actions.SET_EMOJI_SELECTBOX_SELECTED_INDEX,   @setIndex
    @on actions.RESET_EMOJI_SELECTBOX_SELECTED_INDEX, @resetIndex


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
   * It deleted selected index for a given stateId
   *
   * @param {number} currentState
   * @param {string} payload.stateId
   * @return {number} nextState
  ###
  resetIndex: (currentState, { stateId }) ->

    currentState.delete stateId
