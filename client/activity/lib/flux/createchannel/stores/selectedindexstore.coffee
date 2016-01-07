KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'
actions        = require 'activity/flux/createchannel/actions/actiontypes'

###*
 * Store to handle participants-dropdown of create new channel modal selected index
###
module.exports = class CreateNewChannelParticipantsSelectedIndexStore extends KodingFluxStore

  @getterPath = 'CreateNewChannelParticipantsSelectedIndexStore'


  getInitialState: -> 0


  initialize: ->

    @on actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_SELECTED_INDEX,    @setIndex
    @on actions.RESET_CREATE_NEW_CHANNEL_PARTICIPANTS_SELECTED_INDEX , @resetIndex
    @on actions.MOVE_TO_NEXT_CREATE_NEW_CHANNEL_PARTICIPANT_INDEX,     @moveToNextIndex
    @on actions.MOVE_TO_PREV_CREATE_NEW_CHANNEL_PARTICIPANT_INDEX,     @moveToPrevIndex


  ###*
   * It sets current index with given value
   *
   * @param {number} currentState
   * @param {object} payload
   * @param {number} payload.index
   * @return {number} nextState
  ###
  setIndex: (currentState, { index }) -> index


  ###*
   * It resets current index to initial value
   *
   * @param {number} currentState
   * @return {number} nextState
  ###
  resetIndex: (currentState) -> 0


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
