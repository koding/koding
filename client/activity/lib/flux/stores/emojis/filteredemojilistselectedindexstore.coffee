actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

module.exports = class FilteredEmojiListSelectedIndexStore extends KodingFluxStore

  @getterPath = 'FilteredEmojiListSelectedIndexStore'

  getInitialState: -> 0


  initialize: ->

    @on actions.SET_FILTERED_EMOJI_LIST_SELECTET_INDEX,   @setIndex
    @on actions.MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX,   @moveToNextIndex
    @on actions.MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX,   @moveToPrevIndex
    @on actions.RESET_FILTERED_EMOJI_LIST_SELECTET_INDEX, @resetIndex


  setIndex: (currentState, { index }) -> index


  moveToNextIndex: (currentState) -> currentState + 1


  moveToPrevIndex: (currentState) -> currentState - 1


  resetIndex: (currentState) -> 0