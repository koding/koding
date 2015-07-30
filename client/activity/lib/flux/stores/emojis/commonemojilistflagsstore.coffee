actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

module.exports = class CommonEmojiListFlagsStore extends KodingFluxStore

  @getterPath = 'CommonEmojiListFlagsStore'

  getInitialState: -> toImmutable { visible : false, selectionConfirmed : false }


  initialize: ->

    @on actions.SET_COMMON_EMOJI_LIST_VISIBILITY, @setVisibility
    @on actions.TOGGLE_COMMON_EMOJI_LIST_VISIBILITY, @toggleVisibility
    @on actions.CONFIRM_COMMON_EMOJI_LIST_SELECTION, @confirmSelection
    @on actions.RESET_COMMON_EMOJI_LIST_FLAGS, @reset


  setVisibility: (currentState, { visible }) ->

    currentState.set 'visible', visible


  toggleVisibility: (currentState) ->

    visible = currentState.get 'visible'
    currentState.set 'visible', not visible


  confirmSelection: (currentState) ->

    currentState.set 'selectionConfirmed', yes


  reset: (currentState) ->

    currentState.withMutations (map) ->
      map.set('visible', no).set('selectionConfirmed', no)