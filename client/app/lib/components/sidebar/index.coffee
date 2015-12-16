kd                             = require 'kd'
React                          = require 'kd-react'
ReactDOM                       = require 'react-dom'
ActivityFlux                   = require 'activity/flux'
EnvironmentFlux                = require 'app/flux/environment'
Scroller                       = require 'app/components/scroller'
KDReactorMixin                 = require 'app/flux/base/reactormixin'
SidebarStackSection            = require 'app/components/sidebarstacksection'
SidebarChannelsSection         = require 'app/components/sidebarchannelssection'
SidebarMessagesSection         = require 'app/components/sidebarmessagessection'
SidebarSharedMachinesSection   = require 'app/components/sidebarsharedmachinessection'
SharingMachineInvitationWidget = require 'app/components/sidebarmachineslistitem/sharingmachineinvitationwidget'

module.exports = class Sidebar extends React.Component

  PREVIEW_COUNT = 10

  { getters, actions } = ActivityFlux

  getDataBindings: ->
    return {
      publicChannels               : getters.followedPublicChannelThreadsWithSelectedChannel
      privateChannels              : getters.followedPrivateChannelThreads
      selectedThreadId             : getters.selectedChannelThreadId
      stacks                       : EnvironmentFlux.getters.stacks
      sharedMachines               : EnvironmentFlux.getters.sharedMachines
      collaborationMachines        : EnvironmentFlux.getters.collaborationMachines
      sharedMachineListItems       : EnvironmentFlux.getters.sharedMachineListItems
      activeInvitationMachineId    : EnvironmentFlux.getters.activeInvitationMachineId
      activeLeavingSharedMachineId : EnvironmentFlux.getters.activeLeavingSharedMachineId
    }


  popoverNeeded: (machine) ->

    return no  if machine.get('type') is 'own'
    return no  if machine.get('isApproved')
    machine.get('_id') is @state.activeInvitationMachineId


  componentWillMount: ->

    EnvironmentFlux.actions.loadStacks()
    EnvironmentFlux.actions.loadMachines().then => @setActiveInvitationMachineId()
    actions.channel.loadFollowedPublicChannels()
    actions.channel.loadFollowedPrivateChannels()


  renderInvitationWidget: ->

    isRendered = no

    (@state.sharedMachines.concat @state.collaborationMachines).map (machine) =>

      if not isRendered and @popoverNeeded machine
        isRendered = yes
        item   = @state.sharedMachineListItems.get machine.get '_id'
        <SharingMachineInvitationWidget
          listItem={item}
          machine={machine} />


  renderStacks: ->

    stackSections = []
    @state.stacks.toList().map (stack) =>
      stackSections.push \
        <SidebarStackSection
          key={stack.get '_id'}
          previewCount={PREVIEW_COUNT}
          selectedId={@state.selectedThreadId}
          stack={stack}
          machines={stack.get 'machines'}
          onStackRendered={@bound 'onStackRendered'}
          />

    return stackSections


  renderSharedMachines: ->

    machines =
      shared        : @state.sharedMachines
      collaboration : @state.collaborationMachines

    return null  if machines.shared.size is 0 and machines.collaboration.size is 0

    <SidebarSharedMachinesSection
      sectionTitle='Shared VMs'
      activeLeavingSharedMachineId={@state.activeLeavingSharedMachineId}
      machines={machines}/>


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
      {@renderSharedMachines()}
      {@renderChannels()}
      {@renderMessages()}
      {@renderInvitationWidget()}
    </Scroller>


React.Component.include.call Sidebar, [KDReactorMixin]
