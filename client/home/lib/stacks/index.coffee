kd = require 'kd'
sectionize = require '../commons/sectionize'
headerize = require '../commons/headerize'
isFeatureEnabled = require 'app/util/isFeatureEnabled'

HomeStacksCreate = require './homestackscreate'
HomeStacksTeamStacks = require './homestacksteamstacks'
HomeStacksPrivateStacks = require './homestacksprivatestacks'
HomeStacksDisabledUsers = require './homestacksdisableduserstacks'
HomeStacksDrafts = require './homestacksdrafts'
HomeStacksTabHandle = require './homestackstabhandle'
HomeStacksImport = require './homestacksimport'

HomeVirtualMachinesVirtualMachines = require '../virtualmachines/homevirtualmachinesvirtualmachines'
HomeVirtualMachinesConnectedMachines = require '../virtualmachines/homevirtualmachinesconnectedmachines'
HomeVirtualMachinesSharedMachines = require '../virtualmachines/homevirtualmachinessharedmachines'

HomeAccountCredentialsView = require '../account/credentials/homeaccountcredentialsview'
EnvironmentFlux = require 'app/flux/environment'

AddManagedMachineModal = require 'app/providers/managed/addmanagedmachinemodal'
VirtualMachinesSelectedMachineFlux = require 'home/virtualmachines/flux/selectedmachine'

canCreateStacks = require 'app/util/canCreateStacks'
isAdmin = require 'app/util/isAdmin'

module.exports = class HomeStacks extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    @addSubView @topNav  = new kd.TabHandleContainer

    @wrapper.addSubView @tabView = new kd.TabView
      maxHandleWidth       : 'none'
      hideHandleCloseIcons : yes
      detachPanes          : no
      tabHandleContainer   : @topNav
      tabHandleClass       : HomeStacksTabHandle

    @tabView.unsetClass 'kdscrollview'

    @tabView.addPane @stacks      = new kd.TabPaneView { name: 'Stacks' }
    @tabView.addPane @vms         = new kd.TabPaneView { name: 'Virtual Machines' }
    @tabView.addPane @credentials = new kd.TabPaneView { name: 'Credentials' }

    if isFeatureEnabled 'gitlab'
      @tabView.addPane @importView  = new kd.TabPaneView {
        view: new HomeStacksImport
        name: 'Import'
      }

    @tabView.showPane @stacks

    { mainController, computeController, reactor } = kd.singletons

    mainController.ready =>
      @createStacksViews()
      @createVMsViews()
      @createCredentialsViews()

    computeController.on 'MachineBeingDestroyed', (machine) ->
      stack = computeController.findStackFromMachineId machine._id
      reactor.dispatch actions.REMOVE_STACK, stack._id


  handleAction: (action, query) ->

    { onboarding } = kd.singletons

    for pane in @tabView.panes when kd.utils.slugify(pane.name) is action

      @tabView.showPane pane

      switch action
        when 'stacks'
          onboarding.run 'StacksViewed', yes
        when 'virtual-machines'
          VirtualMachinesSelectedMachineFlux.actions.setSelectedMachine null
          onboarding.run 'VMsViewed', yes
        when 'credentials'
          onboarding.run 'CredentialsViewed', yes

      pane.mainView?.handleQuery? query

      break


  handleIdentifier: (identifier, action) ->

    { onboarding } = kd.singletons

    for pane in @tabView.panes when kd.utils.slugify(pane.name) is action
      pane_ = @tabView.showPane pane
      if action is 'virtual-machines'
        {reactor} = kd.singletons
        machine = reactor.evaluate ['MachinesStore']
          .toList()
          .filter (machine) -> machine.get('label') is identifier
          .get(0)

        VirtualMachinesSelectedMachineFlux.actions.setSelectedMachine identifier
        EnvironmentFlux.actions.loadMachineSharedUsers machine.get '_id'  if machine
        onboarding.run 'VMsViewed', yes
      break

  createStacksViews: ->

    { reactor } = kd.singletons
    { actions, getters } = EnvironmentFlux

    actions.loadTeamStackTemplates()
    actions.loadPrivateStackTemplates()

    if canCreateStacks()
      @stacks.addSubView view = new HomeStacksCreate

      view.on 'CreateButtonClick', =>
        @destroy()
        kd.singletons.router.handleRoute '/Stack-Editor/New'

    @stacks.addSubView headerize 'Team Stacks'
    @stacks.addSubView sectionize 'Team Stacks', HomeStacksTeamStacks, { delegate : this }

    @stacks.addSubView headerize 'Private Stacks'
    @stacks.addSubView sectionize 'Private Stacks', HomeStacksPrivateStacks, { delegate : this }

    @stacks.addSubView disabledUsersHeader = headerize 'Disabled User Stacks'
    @stacks.addSubView disabledUsersSection = sectionize 'Disabled User Stacks', HomeStacksDisabledUsers, { deletage: this }

    showDisabledUsers = ->
      disabledUsersHeader.show()
      disabledUsersSection.show()

    hideDisabledUsers = ->
      disabledUsersHeader.hide()
      disabledUsersSection.hide()


    cleanObserver = reactor.observe getters.disabledUsersStackTemplates, (templates) ->
      if templates.size
      then showDisabledUsers()
      else hideDisabledUsers()

    hideDisabledUsers()

    @once 'KDObjectWillBeDestroyed', cleanObserver

    @stacks.addSubView headerize 'Drafts'
    @stacks.addSubView sectionize 'Drafts', HomeStacksDrafts, { delegate : this }


  createVMsViews: ->

    @vms.addSubView headerize 'Virtual Machines'
    @vms.addSubView sectionize 'Virtual Machines', HomeVirtualMachinesVirtualMachines

    @vms.addSubView header = headerize 'Connected Machines'
    header.addSubView new kd.ButtonView
      cssClass : 'GenericButton HomeAppViewVMSection--addOwnMachineButton'
      title    : 'Add Your Own Machine'
      callback : -> new AddManagedMachineModal

    @vms.addSubView sectionize 'Connected Machines', HomeVirtualMachinesConnectedMachines

    @vms.addSubView headerize 'Shared Machines'
    @vms.addSubView sectionize 'Shared Machines', HomeVirtualMachinesSharedMachines


  createCredentialsViews: ->

    @credentials.addSubView headerize 'Credentials'
    @credentials.addSubView sectionize 'Credentials', HomeAccountCredentialsView
