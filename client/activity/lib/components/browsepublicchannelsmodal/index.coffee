kd = require 'kd'
React = require 'kd-react'
SidebarModalList = require 'activity/components/sidebarmodallist'
Modal = require 'app/components/modal'
KDReactorMixin = require 'app/flux/reactormixin'
ActivityFlux = require 'activity/flux'
isPublicChannel = require 'app/util/isPublicChannel'
PublicChannelListItem = require 'activity/components/publicchannellistitem'


module.exports = class BrowsePublicChannelsModal extends React.Component


  getDataBindings: ->
    threads: ActivityFlux.getters.followedPublicChannelThreads
    selectedThread: ActivityFlux.getters.selectedChannelThread


  onItemClick: ->


  onClose: ->

    return  unless @state.selectedThread

    channel = @state.selectedThread.get('channel').toJS()

    route = if isPublicChannel channel
    then "/Channels/#{channel.name}"
    else "/Messages/#{channel.id}"

    kd.singletons.router.handleRoute route


  render: ->

    title = 'Other Channels you are following:'
    <Modal className='ChannelList-Modal' isOpen={yes} onClose={@bound 'onClose'}>
      <SidebarModalList
        title={title}
        searchProp='name'
        threads={@state.threads}
        onItemClick={@bound 'onItemClick'}
        onThresholdAction='loadFollowedPublicChannels'
        itemComponent={PublicChannelListItem}/>
    </Modal>


BrowsePublicChannelsModal.include [KDReactorMixin]

