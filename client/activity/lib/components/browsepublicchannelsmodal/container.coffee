kd              = require 'kd'
React           = require 'kd-react'
View            = require './view'
ActivityFlux    = require 'activity/flux'
isPublicChannel = require 'app/util/isPublicChannel'
KDReactorMixin  = require 'app/flux/base/reactormixin'
Tabs            = require 'activity/constants/sidebarpublicchannelstabs'

module.exports = class BrowsePublicChannelsModalContainer extends React.Component

  @defaultProps =
    isOpen: yes

  skipCloseHandling: no

  getDataBindings: ->

    { getters } = ActivityFlux
    return {
      query          : getters.sidebarPublicChannelsQuery
      tab            : getters.sidebarPublicChannelsTab
      channels       : getters.sidebarPublicChannels
      selectedThread : getters.selectedChannelThread
    }


  isSearchActive: -> if @state.query then yes else no


  # if user clicks on channel in the list, modal will be closed
  # and user will be redirected to channel's page.
  # In this case we don't need to handle onClose event
  onItemClick: -> @skipCloseHandling = yes


  onClose: ->

    return  @skipCloseHandling = no  if @skipCloseHandling
    return  unless @state.selectedThread

    channel = @state.selectedThread.get('channel').toJS()

    route = if isPublicChannel channel
    then "/Channels/#{channel.name}"
    else "/Messages/#{channel.id}"

    kd.singletons.router.handleRoute route


  onYourChannelsClick: ->

    { channel } = ActivityFlux.actions
    channel.loadFollowedPublicChannels()
    channel.setSidebarPublicChannelsTab Tabs.YourChannels


  onOtherChannelsClick: ->

    { channel } = ActivityFlux.actions
    channel.loadChannels()
    channel.setSidebarPublicChannelsTab Tabs.OtherChannels


  onThresholdReached: (options) ->

    { tab, query } = @state
    { channel }    = ActivityFlux.actions
    if @isSearchActive()
      channel.loadChannelsByQuery query, options
    else if tab is Tabs.YourChannels
      channel.loadFollowedPublicChannels options
    else
      channel.loadChannels options


  onSearchInputChange: (event) ->

    { value }   = event.target
    { channel } = ActivityFlux.actions
    channel.loadChannelsByQuery value  if value
    channel.setSidebarPublicChannelsQuery value


  onTabChange: (type) ->

    switch type
      when Tabs.YourChannels then @onYourChannelsClick()
      when Tabs.OtherChannels then @onOtherChannelsClick()


  render: ->

    <View
      isOpen={@props.isOpen}
      query={@state.query}
      onClose={@bound 'onClose'}
      activeTab={@state.tab}
      channels={@state.channels}
      isSearchActive={@isSearchActive()}
      onItemClick={@bound 'onItemClick'}
      onTabChange={@bound 'onTabChange'}
      onThresholdReached={@bound 'onThresholdReached'}
      onSearchInputChange={@bound 'onSearchInputChange'} />


BrowsePublicChannelsModalContainer.include [KDReactorMixin]

