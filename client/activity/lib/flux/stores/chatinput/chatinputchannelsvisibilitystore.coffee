actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

module.exports = class ChatInputChannelsVisibilityStore extends KodingFluxStore

  @getterPath = 'ChatInputChannelsVisibilityStore'


  getInitialState: -> no


  initialize: ->

    @on actions.SET_CHAT_INPUT_CHANNELS_VISIBILITY, @setVisibility


  setVisibility: (currentState, { visible }) -> visible
