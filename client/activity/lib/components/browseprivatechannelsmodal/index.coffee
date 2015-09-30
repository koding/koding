kd = require 'kd'
React = require 'kd-react'
SidebarModalList = require 'activity/components/sidebarmodallist'
Modal = require 'app/components/modal'
KDReactorMixin = require 'app/flux/reactormixin'
ActivityFlux = require 'activity/flux'
isPublicChannel = require 'app/util/isPublicChannel'
PrivateChannelListItem = require 'activity/components/publicchannellistitem'


module.exports = class BrowsePrivateChannelsModal extends React.Component


  getDataBindings: ->
    threads: ActivityFlux.getters.followedPrivateChannelThreads
    selectedThread: ActivityFlux.getters.selectedChannelThread


  onClose: ->

    return  unless @state.selectedThread

    channel = @state.selectedThread.get('channel').toJS()

    route = if isPublicChannel channel
    then "/Channels/#{channel.name}"
    else "/Messages/#{channel.id}"

    kd.singletons.router.handleRoute route


  render: ->

    title = 'Other Messages:'
    <Modal className='ChannelList-Modal' isOpen={yes} onClose={@bound 'onClose'}>
      <SidebarModalList
        title={title}
        searchProp='name'
        threads={@state.threads}
        onThresholdAction='loadFollowedPrivateChannels'
        itemComponent={PrivateChannelListItem}/>
    </Modal>


BrowsePrivateChannelsModal.include [KDReactorMixin]


