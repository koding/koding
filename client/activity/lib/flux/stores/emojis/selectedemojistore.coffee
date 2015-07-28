actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

module.exports = class SelectedEmojiStore extends KodingFluxStore

  @getterPath = 'SelectedEmojiStore'

  getInitialState: -> null


  initialize: ->

    @on actions.SET_SELECTED_EMOJI, @setSelectedEmoji


  setSelectedEmoji: (currentState, { emoji }) -> emoji
