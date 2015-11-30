kd                     = require 'kd'
React                  = require 'kd-react'
ActivityFlux           = require 'activity/flux'
EnvironmentFlux        = require 'app/flux/environment'
KDReactorMixin         = require 'app/flux/base/reactormixin'
SidebarChannelsSection = require 'app/components/sidebarchannelssection'
SidebarMessagesSection = require 'app/components/sidebarmessagessection'
SidebarStackSection    = require 'app/components/sidebarstacksection'
Scroller               = require 'app/components/scroller'

module.exports = class Sidebar extends React.Component

  PREVIEW_COUNT = 10

  { getters, actions } = ActivityFlux

  getDataBindings: ->
    return {
      publicChannels          : getters.followedPublicChannelThreadsWithSelectedChannel
      privateChannels         : getters.followedPrivateChannelThreads
      selectedThreadId        : getters.selectedChannelThreadId
      stacks                  : EnvironmentFlux.getters.stacks
      sharedMachines          : EnvironmentFlux.getters.sharedMachines
      collaborationMachines   : EnvironmentFlux.getters.collaborationMachines
    }


  componentDidMount: ->
    EnvironmentFlux.actions.loadStacks()
    EnvironmentFlux.actions.loadMachines()
    actions.channel.loadFollowedPublicChannels()
    actions.channel.loadFollowedPrivateChannels()


  renderStacks: ->

    stackSections = []
    @state.stacks.toList().map (stack) =>
      stackSections.push \
        <SidebarStackSection
          key={stack.get '_id'}
          previewCount={PREVIEW_COUNT}
          selectedId={@state.selectedThreadId}
          stack={stack}
          machines={stack.getIn [ 'machines' ]}
          />

    return stackSections


  renderSharedVMs: ->

    return null  if @state.sharedMachines.size is 0

    <SidebarStackSection
      sectionTitle='Shared VMs'
      titleLink='/SharedVms'
      />


  renderChannels: ->
    <SidebarChannelsSection
      previewCount={PREVIEW_COUNT}
      selectedId={@state.selectedThreadId}
      threads={@state.publicChannels} />


  renderMessages: ->
    <SidebarMessagesSection
      previewCount={PREVIEW_COUNT}
      selectedId={@state.selectedThreadId}
      threads={@state.privateChannels} />


  render: ->
    <Scroller className={kd.utils.curry 'activity-sidebar', @props.className}>
      {@renderStacks()}
      {@renderSharedVMs()}
      {@renderChannels()}
      {@renderMessages()}
    </Scroller>


React.Component.include.call Sidebar, [KDReactorMixin]
