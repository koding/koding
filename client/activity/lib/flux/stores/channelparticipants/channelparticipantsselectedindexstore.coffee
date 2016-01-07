KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'
actions         = require 'activity/flux/actions/actiontypes'

###*
 * Base class to store and manage selected index of list
###
module.exports = class ChannelParticipantsSelectedIndexStore extends KodingFluxStore

  @getterPath = 'ChannelParticipantsSelectedIndexStore'

  getInitialState: -> 0


  ###*
   * Descendant class should call this method
   * to bind action names to proper methods
   *
   * @param {object} actions
  ###
  initialize: ->

    @on actions.RESET_CHANNEL_PARTICIPANTS_SELECTED_INDEX , @resetIndex
    @on actions.SET_CHANNEL_PARTICIPANTS_SELECTED_INDEX,    @setIndex
    @on actions.MOVE_TO_NEXT_CHANNEL_PARTICIPANT_INDEX,     @moveToNextIndex
    @on actions.MOVE_TO_PREV_CHANNEL_PARTICIPANT_INDEX,     @moveToPrevIndex


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
