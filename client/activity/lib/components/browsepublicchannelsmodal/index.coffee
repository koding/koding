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


module.exports = class BrowsePublicChannelsModal extends React.Component

  MODE = {
    'YOUR_CHANNELS'
    'OTHER_CHANNELS'
    'SEARCH'
  }

  constructor: (props) ->

    super

    @state =
      mode : MODE.YOUR_CHANNELS


  getDataBindings: ->

    filteredPublicChannels: ActivityFlux.getters.filteredPublicChannels


  onItemClick: ->


  onClose: ->

    return  unless @state.selectedThread

    channel = @state.selectedThread.get('channel').toJS()

    route = if isPublicChannel channel
    then "/Channels/#{channel.name}"
    else "/Messages/#{channel.id}"

    kd.singletons.router.handleRoute route


  getTabClassName: (_mode) ->

    { mode } = @state

    isActive = _mode is mode
    return classnames
      'ChannelList-tab' : yes
      'active-tab'      : isActive
      'hidden'          : mode is MODE.SEARCH


  getChannelsClassName: (_mode) ->

    { mode } = @state
    return classnames
      'hidden' : mode is _mode


  handleYourChannelsClick: ->

    @setState { mode : MODE.YOUR_CHANNELS }


  handleOtherChannelsClick: ->

    @setState { mode : MODE.OTHER_CHANNELS }


  renderHeader: ->

    <div>
      <div className='ChannelList-title'>Channels</div>
      <div>
        <input
          className   = 'ChannelList-searchInput'
          placeholder = 'Search'
          ref         = 'ChannelSearchInput'
          value       = { @state.value }
        />
      </div>
    </div>


  render: ->

    { filteredPublicChannels } = @state
    yourChannels  = filteredPublicChannels.followed
    otherChannels = filteredPublicChannels.unfollowed

    <Modal className='ChannelList-Modal' isOpen={yes} onClose={@bound 'onClose'}>
      <div className='ChannelListWrapper'>
        { @renderHeader() }
        <div className={@getTabClassName MODE.YOUR_CHANNELS} onClick={@bound 'handleYourChannelsClick'}>Your Channels</div>
        <div className={@getTabClassName MODE.OTHER_CHANNELS} onClick={@bound 'handleOtherChannelsClick'}>Other Channels</div>
        <SidebarModalThreadList threads={yourChannels} className={@getChannelsClassName MODE.YOUR_CHANNELS} />
        <SidebarModalThreadList threads={otherChannels} className={@getChannelsClassName MODE.OTHER_CHANNELS} />
      </div>
    </Modal>


BrowsePublicChannelsModal.include [KDReactorMixin]

