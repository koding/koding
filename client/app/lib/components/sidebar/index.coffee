_ = require 'lodash'
kd = require 'kd'
Link = require 'app/components/common/link'
React = require 'kd-react'
Scroller = require 'app/components/scroller'
ActivityFlux = require 'activity/flux'
KDReactorMixin = require 'app/flux/base/reactormixin'
EnvironmentFlux = require 'app/flux/environment'
SidebarNoStacks = require 'app/components/sidebarstacksection/sidebarnostacks'
SidebarStackSection = require 'app/components/sidebarstacksection'
SidebarStackHeaderSection = require 'app/components/sidebarstacksection/sidebarstackheadersection'
SidebarSharedMachinesSection = require 'app/components/sidebarsharedmachinessection'
SharingMachineInvitationWidget = require 'app/components/sidebarmachineslistitem/sharingmachineinvitationwidget'
SidebarDifferentStackResources = require 'app/components/sidebarstacksection/sidebardifferentstackresources'


module.exports = class Sidebar extends React.Component

  PREVIEW_COUNT = 10

  { getters, actions } = ActivityFlux

  constructor: ->

    @state =
      showNoStacksWidget : no
      creatingNewStack   : no


  getDataBindings: ->
    return {
      publicChannels               : getters.followedPublicChannelThreadsWithSelectedChannel
      privateChannels              : getters.followedPrivateChannelThreads
      selectedThreadId             : getters.selectedChannelThreadId
      stacks                       : EnvironmentFlux.getters.stacks
      drafts                       : EnvironmentFlux.getters.draftStackTemplates
      sharedMachines               : EnvironmentFlux.getters.sharedMachines
      collaborationMachines        : EnvironmentFlux.getters.collaborationMachines
      sharedMachineListItems       : EnvironmentFlux.getters.sharedMachineListItems
      activeInvitationMachineId    : EnvironmentFlux.getters.activeInvitationMachineId
      activeLeavingSharedMachineId : EnvironmentFlux.getters.activeLeavingSharedMachineId
      requiredInvitationMachine    : EnvironmentFlux.getters.requiredInvitationMachine
      differentStackResourcesStore : EnvironmentFlux.getters.differentStackResourcesStore
    }


  popoverNeeded: (machine) -> machine.get('_id') is @state.activeInvitationMachineId


  componentWillMount: ->

    EnvironmentFlux.actions.loadStacks().then (stacks) =>
      @setState { showNoStacksWidget : yes }  unless stacks.length

    EnvironmentFlux.actions.loadMachines().then @bound 'setActiveInvitationMachineId'

    EnvironmentFlux.actions.loadTeamStackTemplates()
    EnvironmentFlux.actions.loadPrivateStackTemplates()

    actions.channel.loadFollowedPublicChannels()
    actions.channel.loadFollowedPrivateChannels()

    # These listeners needs to be listen those events only once ~ GG
    kd.singletons.notificationController
      .on 'SharedMachineInvitation', EnvironmentFlux.actions.handleSharedMachineInvitation
      .on 'CollaborationInvitation', EnvironmentFlux.actions.handleSharedMachineInvitation
      .on 'MemberWarning',           EnvironmentFlux.actions.handleMemberWarning
      .on 'MachineShareActionTaken', (options) ->
        if options.action is 'approve'
          EnvironmentFlux.actions.setActiveInvitationMachineId { machine: null }
        else
          EnvironmentFlux.actions.setActiveLeavingSharedMachineId { id: null }
          EnvironmentFlux.actions.dispatchCollaborationInvitationRejected options.machineId
          EnvironmentFlux.actions.dispatchSharedVMInvitationRejected options.machineId

        EnvironmentFlux.actions.loadMachines()


  setActiveInvitationMachineId: ->

    { setActiveInvitationMachineId } = EnvironmentFlux.actions

    if @state.requiredInvitationMachine
      setActiveInvitationMachineId { machine : @state.requiredInvitationMachine }


  renderInvitationWidget: ->

    isRendered = no

    (@state.sharedMachines.concat @state.collaborationMachines).toList().map (machine) =>

      if not isRendered and @popoverNeeded machine
        isRendered = yes
        item = @state.sharedMachineListItems.get machine.get '_id'

        <SharingMachineInvitationWidget
          key="InvitationWidget-#{machine.get '_id'}"
          listItem={item}
          machine={machine} />


  prepareStacks:  ->

    stackSections = []
    stackList     =
      koding      : []
      managed     : []

    @state.stacks.toList().map (stack) ->
      provider = if stack.get('title').toLowerCase() is 'managed vms'
      then 'managed'
      else 'koding'

      stackList[provider].push stack

    # Render stacks of koding as first.
    stackList.koding.forEach (stack) => stackSections.push @renderStack stack

    stackSections = stackSections.concat @renderDrafts()

    # Now render stack of managed vms last
    stackList.managed.forEach (stack) => stackSections.push @renderStack stack

    return stackSections


  renderStack: (stack) ->

    <SidebarStackSection
      key={stack.get '_id'}
      previewCount={PREVIEW_COUNT}
      selectedId={@state.selectedThreadId}
      stack={stack}
      machines={stack.get 'machines'}/>


  renderDrafts: ->

    @state.drafts?.toList().toJS().map (template) ->
      id = template._id
      title = _.unescape template.title
      <header key={id} className="SidebarSection-header">
        <h4 className='SidebarSection-headerTitle'>
          <Link href="/Stack-Editor/#{id}">{title}</Link>
        </h4>
      </header>


  renderStacks: ->

    if @state.stacks.size
      <SidebarStackHeaderSection>
        {@prepareStacks()}
      </SidebarStackHeaderSection>
    else if @state.showNoStacksWidget
      <SidebarNoStacks />


  renderDifferentStackResources: ->

    return null  if not @state.differentStackResourcesStore

    <SidebarDifferentStackResources />


  renderSharedMachines: ->

    machines =
      shared        : @state.sharedMachines
      collaboration : @state.collaborationMachines

    return null  if machines.shared.size is 0 and machines.collaboration.size is 0

    <SidebarSharedMachinesSection
      sectionTitle='Shared VMs'
      activeLeavingSharedMachineId={@state.activeLeavingSharedMachineId}
      machines={machines}/>


  renderNewStackSection: ->

    return null  unless @state.creatingNewStack

  renderLogo: ->

    team = kd.singletons.groupsController.getCurrentGroup()
    logo = team.customize?.logo

    if logo
      <img
        src="#{logo}"
        className='Sidebar-footer-logo'
      />
    else
      <object
        type='image/svg+xml'
        data="#{logo or '/a/images/logos/sidebar_footer_logo.svg'}"
        className='Sidebar-footer-logo'>
        Koding Logo
      </object>


  render: ->

    <Scroller className={kd.utils.curry 'activity-sidebar', @props.className}>
      <div className='Sidebar-section-wrapper'>
        {@renderDifferentStackResources()}
        {@renderStacks()}
        {@renderSharedMachines()}
        {@renderInvitationWidget()}
      </div>
      <div className='Sidebar-logo-wrapper'>
        {@renderLogo()}
      </div>
    </Scroller>


React.Component.include.call Sidebar, [KDReactorMixin]
