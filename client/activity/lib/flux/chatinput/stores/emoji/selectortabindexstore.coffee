actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

###*
 * Store to handle emoji selector current tab index
###
module.exports = class EmojiSelectorTabIndexStore extends KodingFluxStore

  @getterPath = 'EmojiSelectorTabIndexStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SET_EMOJI_SELECTOR_TAB_INDEX, @setTabIndex


  ###*
   * Handler of SET_EMOJI_SELECTOR_TAB_INDEX action
   * It updates current tab index for a given stateId
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @param {number} payload.tabIndex
   * @return {Immutable.Map} nextState
  ###
  setTabIndex: (currentState, { stateId, tabIndex }) ->

    currentState.set stateId, tabIndex

