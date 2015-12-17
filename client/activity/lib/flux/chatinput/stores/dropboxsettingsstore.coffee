actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'


module.exports = class ChatInputDropboxSettingsStore extends KodingFluxStore

  @getterPath = 'ChatInputDropboxSettingsStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SET_DROPBOX_QUERY, @setQuery
    @on actions.SET_DROPBOX_SELECTED_INDEX, @setIndex
    @on actions.MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX, @moveToNextIndex
    @on actions.MOVE_TO_PREV_DROPBOX_SELECTED_INDEX, @moveToPrevIndex
    @on actions.RESET_DROPBOX, @reset


  setQuery: (currentState, { stateId, query, type }) ->

    currentState = helper.ensureSettingsMap currentState, stateId
    currentState = currentState.setIn [ stateId, 'query' ], query
    currentState = currentState.setIn [ stateId, 'type' ], type
    currentState = currentState.setIn [ stateId, 'index' ], 0


  setIndex: (currentState, { stateId, index }) ->

    currentState = helper.ensureSettingsMap currentState, stateId
    currentState.setIn [ stateId, 'index' ], index


  moveToNextIndex: (currentState, { stateId }) ->

    currentState = helper.ensureSettingsMap currentState, stateId
    index        = currentState.getIn [ stateId, 'index' ], 0
    currentState.setIn [ stateId, 'index' ], index + 1


  moveToPrevIndex: (currentState, { stateId }) ->

    currentState = helper.ensureSettingsMap currentState, stateId
    index        = currentState.getIn [ stateId, 'index' ], 0
    currentState.setIn [ stateId, 'index' ], index - 1


  reset: (currentState, { stateId }) ->

    currentState = helper.ensureSettingsMap currentState, stateId
    currentState = currentState.setIn [ stateId, 'query' ], ''
    currentState = currentState.setIn [ stateId, 'type' ], ''
    currentState = currentState.setIn [ stateId, 'index' ], 0


  helper =

    ensureSettingsMap: (currentState, stateId) ->

      unless currentState.has stateId
        return currentState.set stateId, immutable.Map()

      return currentState

