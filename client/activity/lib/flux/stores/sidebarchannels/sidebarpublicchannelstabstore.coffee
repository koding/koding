actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
Tabs            = require './sidebarpublicchannelstabs'

###*
 * Store to handle current tab of sidebar public channels.
 * It listens for SET_SIDEBAR_PUBLIC_CHANNELS_TAB action
 * and updates current state with the given value
###
module.exports = class SidebarPublicChannelsTabStore extends KodingFluxStore

  @getterPath = 'SidebarPublicChannelsTabStore'

  getInitialState: -> Tabs.YourChannels

  initialize: ->

    @on actions.SET_SIDEBAR_PUBLIC_CHANNELS_TAB, @setTab


  setTab: (currentState, { tab }) -> tab

