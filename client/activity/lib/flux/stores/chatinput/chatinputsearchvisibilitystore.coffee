actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

###*
 * Store to handle chat input search visibility flag
###
module.exports = class ChatInputSearchVisibilityStore extends KodingFluxStore

  @getterPath = 'ChatInputSearchVisibilityStore'


  getInitialState: -> no


  initialize: ->

    @on actions.SET_CHAT_INPUT_SEARCH_VISIBILITY, @setVisibility


  ###*
   * It updates current visibility flag with a given value
   *
   * @param {number} currentState
   * @param {object} payload
   * @param {bool} payload.visible
   * @return {bool} nextState
  ###
  setVisibility: (currentState, { visible }) -> visible

