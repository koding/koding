actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

module.exports = class SelectedEmojiIndexStore extends KodingFluxStore

  @getterPath = 'SelectedEmojiIndexStore'

  getInitialState: -> toImmutable { index : 0, confirmed : no }


  initialize: ->

    @on actions.SET_SELECTED_EMOJI_INDEX, @setIndex
    @on actions.MOVE_TO_NEXT_EMOJI_INDEX, @moveToNextIndex
    @on actions.MOVE_TO_PREV_EMOJI_INDEX, @moveToPrevIndex
    @on actions.CONFIRM_SELECTED_EMOJI_INDEX, @confirm
    @on actions.UNSET_SELECTED_EMOJI_INDEX, @reset


  setIndex: (currentState, { index }) ->

    currentState.set 'index', index


  moveToNextIndex: (currentState) ->

    index = currentState.get 'index'
    currentState.set 'index', index + 1


  moveToPrevIndex: (currentState) ->

    index = currentState.get 'index'
    currentState.set 'index', index - 1


  confirm: (currentState) ->

    currentState.set 'confirmed', yes


  reset: (currentState) ->

    currentState.withMutations (map) ->
      map.set('index', 0).set('confirmed', no)