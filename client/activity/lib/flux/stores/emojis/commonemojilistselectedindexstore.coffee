actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

module.exports = class CommonEmojiListSelectedIndexStore extends KodingFluxStore

  @getterPath = 'CommonEmojiListSelectedIndexStore'

  getInitialState: -> 0


  initialize: ->

    @on actions.SET_COMMON_EMOJI_LIST_SELECTED_INDEX, @setIndex
    @on actions.RESET_COMMON_EMOJI_LIST_SELECTED_INDEX, @resetIndex


  setIndex: (currentState, { index }) -> index


  resetIndex: (currentState) -> 0
