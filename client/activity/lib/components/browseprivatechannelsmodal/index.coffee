kd = require 'kd'
React = require 'kd-react'
SidebarModalList = require 'activity/components/sidebarmodallist'
Modal = require 'app/components/modal'
KDReactorMixin = require 'app/flux/reactormixin'
ActivityFlux = require 'activity/flux'
isPublicChannel = require 'app/util/isPublicChannel'
PrivateChannelListItem = require 'activity/components/privatechannellistitem'
isNodeInRoot = require 'app/util/isnodeinroot'


module.exports = class BrowsePrivateChannelsModal extends React.Component


  getDataBindings: ->
    threads: ActivityFlux.getters.followedPrivateChannelThreads
    selectedThread: ActivityFlux.getters.selectedChannelThread


  # if user clicks on channel in the list, modal will be closed
  # and user will be redirected to channel's page.
  # In this case we don't need to handle onClose event
  onItemClick: (event) -> @skipCloseHandling = yes


  onClose: ->

    return  @skipCloseHandling = no  if @skipCloseHandling
    return  unless @state.selectedThread

    channel = @state.selectedThread.get('channel').toJS()

    route = if isPublicChannel channel
    then "/Channels/#{channel.name}"
    else "/Messages/#{channel.id}"

    kd.singletons.router.handleRoute route


  # we can use this methodology when multiple modals shown same time.
  handleMouseClickOutside: (event) ->

    { target } = event

    ActivityPromptModal = document.querySelector('.ActivityPromptModal')

    return  if isNodeInRoot(target, ActivityPromptModal)

    return @onClose()  unless isNodeInRoot target, React.findDOMNode @refs.ModalWrapper


  render: ->

    title = 'Other Messages:'
    <Modal ref='ModalWrapper' className='ChannelList-Modal' handleMouseClickOutside={@bound 'handleMouseClickOutside'} isOpen={yes} onClose={@bound 'onClose'}>
      <SidebarModalList
        title={title}
        searchProp='name'
        threads={@state.threads}
        onThresholdAction='loadFollowedPrivateChannels'
        onItemClick={@bound 'onItemClick'}
        itemComponent={PrivateChannelListItem}/>
    </Modal>


BrowsePrivateChannelsModal.include [KDReactorMixin]


