actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to handle chat input dropbox state
###
module.exports = class ChatInputDropboxSettingsStore extends KodingFluxStore

  @getterPath = 'ChatInputDropboxSettingsStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SET_DROPBOX_QUERY_AND_CONFIG, @setQueryAndConfig
    @on actions.SET_DROPBOX_SELECTED_INDEX, @setIndex
    @on actions.MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX, @moveToNextIndex
    @on actions.MOVE_TO_PREV_DROPBOX_SELECTED_INDEX, @moveToPrevIndex
    @on actions.RESET_DROPBOX, @reset


  ###*
   * A handler for SET_DROPBOX_QUERY_AND_CONFIG action.
   * It updates dropbox query and config for a given stateId
   * and resets dropbox index to 0
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @param {string} payload.query
   * @param {object} payload.config
   * @return {immutable.Map} nextState
  ###
  setQueryAndConfig: (currentState, { stateId, query, config }) ->

    currentState = helper.ensureSettingsMap currentState, stateId
    currentState = currentState.setIn [ stateId, 'query' ], query
    currentState = currentState.setIn [ stateId, 'config' ], toImmutable config
    currentState = currentState.setIn [ stateId, 'index' ], 0


  ###*
   * A handler for SET_DROPBOX_SELECTED_INDEX action.
   * It updates dropbox index for a given stateId
   * only if dropbox config is set
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @param {number} payload.index
   * @return {immutable.Map} nextState
  ###
  setIndex: (currentState, { stateId, index }) ->

    currentState = helper.ensureSettingsMap currentState, stateId
    return currentState  unless currentState.getIn [ stateId, 'config' ]
    currentState.setIn [ stateId, 'index' ], index


  ###*
   * A handler for MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX action.
   * It increments dropbox index for a given stateId
   * only if dropbox config is set
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @return {immutable.Map} nextState
  ###
  moveToNextIndex: (currentState, { stateId }) ->

    currentState = helper.ensureSettingsMap currentState, stateId
    return currentState  unless currentState.getIn [ stateId, 'config' ]
    index        = currentState.getIn [ stateId, 'index' ], 0
    currentState.setIn [ stateId, 'index' ], index + 1


  ###*
   * A handler for MOVE_TO_PREV_DROPBOX_SELECTED_INDEX action.
   * It decrements dropbox index for a given stateId
   * only if dropbox config is set
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @return {immutable.Map} nextState
  ###
  moveToPrevIndex: (currentState, { stateId }) ->

    currentState = helper.ensureSettingsMap currentState, stateId
    return currentState  unless currentState.getIn [ stateId, 'config' ]
    index        = currentState.getIn [ stateId, 'index' ], 0
    currentState.setIn [ stateId, 'index' ], index - 1


  ###*
   * A handler for RESET_DROPBOX action.
   * It deletes dropbox state for a given stateId
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @return {immutable.Map} nextState
  ###
  reset: (currentState, { stateId }) ->

    currentState = helper.ensureSettingsMap currentState, stateId
    currentState = currentState.remove stateId


  helper =

    ensureSettingsMap: (currentState, stateId) ->

      unless currentState.has stateId
        return currentState.set stateId, immutable.Map()

      return currentState
