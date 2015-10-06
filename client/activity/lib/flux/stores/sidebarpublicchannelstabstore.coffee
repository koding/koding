actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
Tabs            = require './sidebarpublicchannelstabs'


module.exports = class SidebarPublicChannelsTabStore extends KodingFluxStore

  @getterPath = 'SidebarPublicChannelsTabStore'

  getInitialState: -> Tabs.YourChannels

  initialize: ->

    @on actions.SET_SIDEBAR_PUBLIC_CHANNELS_TAB, @setTab


  setTab: (currentState, { tab }) -> tab

