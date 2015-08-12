kd                     = require 'kd'
React                  = require 'kd-react'
ActivityFlux           = require 'activity/flux'
KDReactorMixin         = require 'app/flux/reactormixin'
SidebarChannelsSection = require 'activity/components/sidebarchannelssection'


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

  renderChannelsSection: ->
    <SidebarChannelsSection
      threads={@state.publicChannels}
      selectedId={@state.selectedThreadId} />


  render: ->
    <div className="SidebarSections">
      {@renderChannelsSection()}
    </div>


React.Component.include.call SidebarSections, [KDReactorMixin]
