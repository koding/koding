actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

module.exports = class FilteredEmojiListFlagsStore extends KodingFluxStore

  @getterPath = 'FilteredEmojiListFlagsStore'

  getInitialState: -> toImmutable { selectionConfirmed : no }


  initialize: ->

    @on actions.CONFIRM_FILTERED_EMOJI_LIST_SELECTION, @confirmSelection
    @on actions.RESET_FILTERED_EMOJI_LIST_FLAGS, @reset


  confirmSelection: (currentState) ->

    currentState.set 'selectionConfirmed', yes


  reset: (currentState) ->

    currentState.set 'selectionConfirmed', no
