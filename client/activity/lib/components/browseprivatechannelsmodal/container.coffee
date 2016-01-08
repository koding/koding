kd              = require 'kd'
React           = require 'kd-react'
View            = require './view'
ActivityFlux    = require 'activity/flux'
isPublicChannel = require 'app/util/isPublicChannel'
KDReactorMixin  = require 'app/flux/base/reactormixin'

module.exports = class BrowsePrivateChannelsModalContainer extends React.Component

  @defaultProps =
    isOpen : yes

  skipCloseHandling: no


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


  render: ->

    <View
      isOpen={@props.isOpen}
      onClose={@bound 'onClose'}
      threads={@state.threads}
      onItemClick={@bound 'onItemClick'}/>

BrowsePrivateChannelsModalContainer.include [KDReactorMixin]

