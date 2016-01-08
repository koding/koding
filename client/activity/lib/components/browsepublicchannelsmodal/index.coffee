kd = require 'kd'
React = require 'kd-react'
SidebarModalList = require 'activity/components/sidebarmodallist'
Modal = require 'app/components/modal'
KDReactorMixin = require 'app/flux/base/reactormixin'
ActivityFlux = require 'activity/flux'
isPublicChannel = require 'app/util/isPublicChannel'
PublicChannelListItem = require 'activity/components/publicchannellistitem'
classnames = require 'classnames'
SidebarModalThreads = require 'activity/components/sidebarmodalthreads'
Tabs = require 'activity/flux/stores/sidebarchannels/sidebarpublicchannelstabs'

module.exports = class BrowsePublicChannelsModal extends React.Component

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


  getTabClassName: (isYoursChannels) ->

    { tab } = @state

    isActive = if isYoursChannels
    then tab is Tabs.YourChannels
    else tab is Tabs.OtherChannels

    return classnames
      'ChannelList-tab' : yes
      'active-tab'      : isActive


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

    className = classnames
      'ChannelList-tabs' : yes
      'hidden'           : @isSearchActive()

    <div className={className}>
      <div className={@getTabClassName yes} onClick={@bound 'onYourChannelsClick'}>Your Channels</div>
      <div className={@getTabClassName no} onClick={@bound 'onOtherChannelsClick'}>Other Channels</div>
      <div className='clearfix'></div>
    </div>


  renderList: ->

    { channels } = @state
    noResutText  = 'Sorry, your search did not have any results'  if @isSearchActive()

    <SidebarModalThreads
      threads            = { channels }
      noResultText       = { noResutText }
      onThresholdReached = { @bound 'onThresholdReached' }
      onItemClick        = { @bound 'onItemClick' }
    />


  render: ->

    className = classnames
      'ChannelListWrapper' : yes
      'active-search'      : @isSearchActive()

    <Modal className='ChannelList-Modal PublicChannelListModal' isOpen={yes} onClose={@bound 'onClose'}>
      <div className={className}>
        { @renderHeader() }
        { @renderTabs() }
        { @renderList() }
      </div>
    </Modal>


BrowsePublicChannelsModal.include [KDReactorMixin]
