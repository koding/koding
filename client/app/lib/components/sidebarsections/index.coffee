kd                     = require 'kd'
React                  = require 'kd-react'
ActivityFlux           = require 'activity/flux'
KDReactorMixin         = require 'app/flux/reactormixin'
SidebarChannelsSection = require 'app/components/sidebarchannelssection'
SidebarMessagesSection = require 'app/components/sidebarmessagessection'


module.exports = class SidebarSections extends React.Component


  { getters, actions } = ActivityFlux

  getDataBindings: ->
    return {
      publicChannels   : getters.followedPublicChannelThreads
      privateChannels  : getters.followedPrivateChannelThreads
      selectedThreadId : getters.selectedChannelThreadId
    }


  componentDidMount: ->
    actions.channel.loadFollowedPublicChannels()
    actions.channel.loadFollowedPrivateChannels()


  renderChannelsSection: ->
    <SidebarChannelsSection
      threads={@state.publicChannels}
      selectedId={@state.selectedThreadId} />


  renderMessagesSection: ->
    <SidebarMessagesSection
      threads={@state.privateChannels}
      selectedId={@state.selectedThreadId} />


  render: ->
    <div className="SidebarSections">
      {@renderChannelsSection()}
      {@renderMessagesSection()}
    </div>


React.Component.include.call SidebarSections, [KDReactorMixin]
