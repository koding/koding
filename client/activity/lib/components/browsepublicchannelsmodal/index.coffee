kd = require 'kd'
React = require 'kd-react'
SidebarModalList = require 'activity/components/sidebarmodallist'
Modal = require 'app/components/modal'
KDReactorMixin = require 'app/flux/reactormixin'
ActivityFlux = require 'activity/flux'
isPublicChannel = require 'app/util/isPublicChannel'
PublicChannelListItem = require 'activity/components/publicchannellistitem'
classnames = require 'classnames'
SidebarModalThreadList = require 'activity/components/sidebarmodalthreadlist'
Tabs = require 'activity/flux/stores/sidebarchannels/sidebarpublicchannelstabs'

module.exports = class BrowsePublicChannelsModal extends React.Component

  getDataBindings: ->

    query          : ActivityFlux.getters.sidebarPublicChannelsQuery
    tab            : ActivityFlux.getters.sidebarPublicChannelsTab
    channels       : ActivityFlux.getters.sidebarPublicChannels
    selectedThread : ActivityFlux.getters.selectedChannelThread


  onItemClick: ->


  onClose: ->

    return  unless @state.selectedThread

    channel = @state.selectedThread.get('channel').toJS()

    route = if isPublicChannel channel
    then "/Channels/#{channel.name}"
    else "/Messages/#{channel.id}"

    kd.singletons.router.handleRoute route


  getTabClassName: (isYoursChannels) ->

    { tab, query } = @state

    isActive = if isYoursChannels
    then tab is Tabs.YourChannels
    else tab is Tabs.OtherChannels
    return classnames
      'ChannelList-tab' : yes
      'active-tab'      : isActive
      'hidden'          : query


  onYourChannelsClick: ->

    ActivityFlux.actions.channel.loadFollowedPublicChannels()
    ActivityFlux.actions.channel.setSidebarPublicChannelsTab Tabs.YourChannels


  onOtherChannelsClick: ->

    ActivityFlux.actions.channel.loadChannels()
    ActivityFlux.actions.channel.setSidebarPublicChannelsTab Tabs.OtherChannels


  onYourChannelsThresholdReached: (options) ->

    #ActivityFlux.actions.channel.loadFollowedPublicChannels options


  onOtherChannelsThresholdReached: (options) ->

    #ActivityFlux.actions.channel.loadChannels options


  onSearchInputChange: (event) ->

    { value } = event.target
    ActivityFlux.actions.channel.loadChannelsByQuery value  if value
    ActivityFlux.actions.channel.setSidebarPublicChannelsQuery value


  renderHeader: ->

    { query } = @state

    <div>
      <div className='ChannelList-title'>Channels</div>
      <div>
        <input
          className   = 'ChannelList-searchInput'
          placeholder = 'Search'
          ref         = 'ChannelSearchInput'
          value       = { query }
          onChange    = { @bound 'onSearchInputChange' }
        />
      </div>
    </div>


  renderTabs: ->

    { query } = @state

    <div className={if query then 'hidden'}>
      <div className={@getTabClassName yes} onClick={@bound 'onYourChannelsClick'}>Your Channels</div>
      <div className={@getTabClassName no} onClick={@bound 'onOtherChannelsClick'}>Other Channels</div>
      <div className='clearfix'></div>
    </div>


  render: ->

    { channels } = @state

    <Modal className='ChannelList-Modal' isOpen={yes} onClose={@bound 'onClose'}>
      <div className='ChannelListWrapper'>
        { @renderHeader() }
        { @renderTabs() }
        <SidebarModalThreadList threads={channels} onThreasholdReached={ @bound 'onYourChannelsThresholdReached' }  />
      </div>
    </Modal>


BrowsePublicChannelsModal.include [KDReactorMixin]

