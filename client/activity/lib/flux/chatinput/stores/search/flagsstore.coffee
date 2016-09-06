actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
immutable       = require 'immutable'

###*
 * Store to handle chat input search flags
###
module.exports = class ChatInputSearchFlagsStore extends KodingFluxStore

  @getterPath = 'ChatInputSearchFlagsStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.CHAT_INPUT_SEARCH_BEGIN, @handleSearchBegin
    @on actions.CHAT_INPUT_SEARCH_SUCCESS, @handleSearchEnd
    @on actions.CHAT_INPUT_SEARCH_FAIL, @handleSearchEnd
    @on actions.CHAT_INPUT_SEARCH_RESET, @handleSearchEnd


  ###*
   * It sets 'isLoading' flag to yes for a given stateId
   * when search is started
   *
   * @param {immutable.Map} flags
   * @param {object} payload
   * @param {bool} payload.stateId
   * @return {immutable.Map} nextState
  ###
  handleSearchBegin: (flags, { stateId }) ->

    flags = helper.ensureFlagsMap flags, stateId
    flags.setIn [stateId, 'isLoading'], yes


  ###*
   * It sets 'isLoading' flag to no for a given stateId
   * when search is ended
   *
   * @param {immutable.Map} flags
   * @param {object} payload
   * @param {bool} payload.stateId
   * @return {immutable.Map} nextState
  ###
  handleSearchEnd: (flags, { stateId }) ->

    flags = helper.ensureFlagsMap flags, stateId
    flags.setIn [stateId, 'isLoading'], no


helper =

  ensureFlagsMap: (flags, stateId) ->

    unless flags.has stateId
      return flags.set stateId, immutable.Map()

    return flags
