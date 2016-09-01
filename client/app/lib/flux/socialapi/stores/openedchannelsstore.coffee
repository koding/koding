KodingFluxStore = require 'app/flux/base/store'
actions         = require '../actions/actiontypes'
immutable       = require 'immutable'

module.exports = class OpenedChannelsStore extends KodingFluxStore

  @getterPath = 'OpenedChannelsStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_MESSAGES_SUCCESS, (openedChannels, { channelId }) ->
      openedChannels.set channelId, yes
