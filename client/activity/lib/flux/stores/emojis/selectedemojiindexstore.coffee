actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
EmojiConstants  = require 'activity/flux/emojiconstants'

module.exports = class SelectedEmojiIndexStore extends KodingFluxStore

  @getterPath = 'SelectedEmojiIndexStore'

  getInitialState: -> EmojiConstants.UNSELECTED_EMOJI_INDEX


  initialize: ->

    @on actions.SET_SELECTED_EMOJI_INDEX, @setSelectedIndex
    @on actions.MOVE_TO_NEXT_EMOJI_INDEX, @moveToNextIndex
    @on actions.MOVE_TO_PREV_EMOJI_INDEX, @moveToPrevIndex


  setSelectedIndex: (currentState, { index }) -> index


  moveToNextIndex: (currentState) ->

    if currentState is EmojiConstants.UNSELECTED_EMOJI_INDEX
    then 1
    else currentState + 1


  moveToPrevIndex: (currentState) ->

    if currentState is EmojiConstants.UNSELECTED_EMOJI_INDEX
    then -1
    else currentState - 1
