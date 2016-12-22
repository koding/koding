_ = require 'lodash'
kd = require 'kd'
Link = require 'app/components/common/link'
React = require 'app/react'
Scroller = require 'app/components/scroller'
KDReactorMixin = require 'app/flux/base/reactormixin'
EnvironmentFlux = require 'app/flux/environment'
SidebarNoStacks = require 'app/components/sidebarstacksection/sidebarnostacks'
SidebarStackSection = require 'app/components/sidebarstacksection'
SidebarStackHeaderSection = require 'app/components/sidebarstacksection/sidebarstackheadersection'
SidebarSharedMachinesSection = require 'app/components/sidebarsharedmachinessection'
SharingMachineInvitationWidget = require 'app/components/sidebarmachineslistitem/sharingmachineinvitationwidget'
SidebarDifferentStackResources = require 'app/components/sidebarstacksection/sidebardifferentstackresources'
SidebarGroupDisabled = require './groupdisabled'
isGroupDisabled = require 'app/util/isGroupDisabled'
getGroup = require 'app/util/getGroup'
{ findDOMNode } = require 'react-dom'
SidebarFlux = require 'app/flux/sidebar'
TeamFlux = require 'app/flux/teams'
DEFAULT_LOGOPATH = '/a/images/logos/sidebar_footer_logo.svg'
MENU = null
isAdmin = require 'app/util/isAdmin'
remote = require 'app/remote'
whoami = require 'app/util/whoami'

canCreateStacks = require 'app/util/canCreateStacks'

require './styl/sidebar.styl'
require './styl/sidebarmenu.styl'

module.exports = class Sidebar extends React.Component

  constructor: (props) ->

    super props

    @state = { isLoading: yes }


  getDataBindings: ->
    return {
      stacks                       : SidebarFlux.getters.sidebarStacks
      drafts                       : SidebarFlux.getters.sidebarDrafts
      sharedMachines               : EnvironmentFlux.getters.sharedMachines
      collaborationMachines        : EnvironmentFlux.getters.collaborationMachines
      sharedMachineListItems       : EnvironmentFlux.getters.sharedMachineListItems
      activeInvitationMachineId    : EnvironmentFlux.getters.activeInvitationMachineId
      activeLeavingSharedMachineId : EnvironmentFlux.getters.activeLeavingSharedMachineId
      requiredInvitationMachine    : EnvironmentFlux.getters.requiredInvitationMachine
      differentStackResourcesStore : EnvironmentFlux.getters.differentStackResourcesStore
      allStackTemplates            : EnvironmentFlux.getters.allStackTemplates
      team                         : TeamFlux.getters.team
      selectedTemplateId           : EnvironmentFlux.getters.selectedTemplateId
    }


  popoverNeeded: (machine) -> machine.get('_id') is @state.activeInvitationMachineId


  componentWillMount: ->

    TeamFlux.actions.loadTeam()

    SidebarFlux.actions.loadVisibilityFilters().then =>
      EnvironmentFlux.actions.loadStacks().then =>
        @setState { isLoading: no }

      EnvironmentFlux.actions.loadMachines().then @bound 'setActiveInvitationMachineId'

      EnvironmentFlux.actions.loadTeamStackTemplates()
      EnvironmentFlux.actions.loadPrivateStackTemplates()

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
          EnvironmentFlux.actions.dispatchSharedVMInvitationRejected options.uid

        EnvironmentFlux.actions.loadMachines()


  onMenuItemClick: (id, item, event) ->

    { router, linkController, appManager, computeController } = kd.singletons
    { title } = item.getData()

    MENU.destroy()

    draft = @state.drafts.get id
    switch title
      when 'Edit', 'View Stack' then router.handleRoute "/Stack-Editor/#{id}"
      when 'Initialize'
        EnvironmentFlux.actions.generateStack(id).then ({ template }) ->
          appManager.tell 'Stackeditor', 'reloadEditor', template._id
      when 'Clone'
        EnvironmentFlux.actions.cloneStackTemplate remote.revive draft.toJS()
      when 'Open on GitLab'
        remoteUrl = draft.getIn ['config', 'remoteDetails', 'originalUrl']
        linkController.openOrFocus remoteUrl
      when 'Make Team Default'
        computeController.makeTeamDefault remote.revive draft.toJS()
      when 'Delete'
        computeController.deleteStackTemplate remote.revive draft.toJS()
      when 'Share With Team'
        computeController.setStackTemplateAccessLevel remote.revive(draft.toJS()), 'group'
      when 'Make Private'
        computeController.setStackTemplateAccessLevel remote.revive(draft.toJS()), 'private'



  onDraftTitleClick: (id, event) ->

    kd.utils.stopDOMEvent event

    lastLayer = kd.singletons.windowController.layers?.first

    return  if MENU

    callback = (item, event) => @onMenuItemClick id, item, event

    menuItems = {}
    draft = @state.drafts.get id

    if draft.getIn ['config', 'remoteDetails', 'originalUrl']
      menuItems['Open on GitLab'] = { callback }
    if whoami()._id is draft.get 'originId'
      menuItems['Edit'] = { callback }
    else
      menuItems['View Stack'] = { callback }

    menuItems['Initialize'] = { callback }
    menuItems['Clone'] = { callback }  if canCreateStacks() or isAdmin()

    if draft.get('machines').size
      menuItems['Make Team Default'] = { callback } if isAdmin()
      if whoami()._id is draft.get('originId')
        if draft.get('accessLevel') is 'private'
        then menuItems['Share With Team'] = { callback }
        else  menuItems['Make Private'] = { callback }

    menuItems['Delete'] = { callback }

    { top } = findDOMNode(@refs["draft-#{id}"]).getBoundingClientRect()

    menuOptions = { cssClass: 'SidebarMenu', x: 36, y: top + 31 }

    MENU = new kd.ContextMenu menuOptions, menuItems

    MENU.once 'KDObjectWillBeDestroyed', -> kd.utils.wait 50, -> MENU = null


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

    template = @state.allStackTemplates.get stack.get 'baseStackId'

    <SidebarStackSection
      key={stack.get '_id'}
      selectedId={@state.selectedThreadId}
      stack={stack}
      template={template}
      machines={stack.get 'machines'}/>


  onTitleClick: (id) ->

    kd.singletons.router.handleRoute "/Stack-Editor/#{id}"


  renderDrafts: ->

    @state.drafts?.toList().toJS().map (template) =>
      id = template._id
      title = _.unescape template.title
      className = 'SidebarSection SidebarStackSection draft'
      className += ' active'  if @state.selectedTemplateId is id
      <section key={id} className={className}>
        <header
          ref="draft-#{id}"
          className="SidebarSection-header">
          <h4 className='SidebarSection-headerTitle'>
            <Link href="/Stack-Editor/#{id}" onClick={@onTitleClick.bind this, id}>{title}</Link>
          </h4>
          <div onClick={@onDraftTitleClick.bind this, id} className='menu-icon'></div>
        </header>
      </section>


  renderStacks: ->

    if isGroupDisabled getGroup()
      <SidebarGroupDisabled />
    else if @state.stacks.size or @state.drafts.size
      <SidebarStackHeaderSection>
        {@prepareStacks()}
      </SidebarStackHeaderSection>
    else if @state.isLoading
      <div/>
    else
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


  renderLogo: ->

    <img src="#{DEFAULT_LOGOPATH}" className='Sidebar-footer-logo' />


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
