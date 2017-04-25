kd = require 'kd'
sectionize = require '../commons/sectionize'
headerize = require '../commons/headerize'
hasIntegration = require 'app/util/hasIntegration'

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

    if hasIntegration 'gitlab'
      @tabView.addPane @importView  = new kd.TabPaneView {
        view: new HomeStacksImport { delegate: this.wrapper }
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
          EnvironmentFlux.actions.setSelectedMachineId null
          onboarding.run 'VMsViewed', yes
        when 'credentials'
          onboarding.run 'CredentialsViewed', yes

      if (Object.keys query).length
        pane.mainView?.handleQuery? query

      break


  handleIdentifier: (identifier, action) ->

    { onboarding } = kd.singletons
    { setSelectedMachineId, loadMachineSharedUsers } = EnvironmentFlux.actions

    for pane in @tabView.panes when kd.utils.slugify(pane.name) is action
      pane_ = @tabView.showPane pane
      if action is 'virtual-machines'
        { sidebar, computeController } = kd.singletons
        { storage } = computeController

        if machine = storage.machines.get '_id', identifier
          machine.reviveUsers { permanentOnly: yes }

        setSelectedMachineId identifier
        onboarding.run 'VMsViewed', yes
      break

  createStacksViews: ->

    { reactor, computeController } = kd.singletons
    { actions, getters } = EnvironmentFlux

    actions.loadStackTemplates()

    if canCreateStacks()
      @stacks.addSubView view = new HomeStacksCreate

      view.on 'CreateButtonClick', ->
        kd.singletons.appManager
          .tell 'Stackeditor', 'openStackWizard', handleRoute = no

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

    { storage } = computeController

    checkStorage = ->
      disabledUserStacks = storage.stacks.get().filter (s) -> s.getOldOwner()

      if disabledUserStacks.length
      then showDisabledUsers()
      else hideDisabledUsers()

    # check disabled user stacks initially
    checkStorage()

    # check disabled user stacks on each change
    storage.on 'change', checkStorage
    @once 'KDObjectWillBeDestroyed', -> storage.off 'change', checkStorage

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
