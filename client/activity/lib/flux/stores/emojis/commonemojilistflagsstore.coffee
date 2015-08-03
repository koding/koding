actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

module.exports = class CommonEmojiListFlagsStore extends KodingFluxStore

  @getterPath = 'CommonEmojiListFlagsStore'

  getInitialState: -> toImmutable { visible : no }


  initialize: ->

    @on actions.SET_COMMON_EMOJI_LIST_VISIBILITY, @setVisibility
    @on actions.RESET_COMMON_EMOJI_LIST_FLAGS, @reset


  setVisibility: (currentState, { visible }) ->

    currentState.set 'visible', visible


  reset: (currentState) ->

    currentState.set 'visible', no