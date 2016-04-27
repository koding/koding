kd = require 'kd'
sectionize = require '../commons/sectionize'
headerize = require '../commons/headerize'

HomeStacksCreate = require './homestackscreate'
HomeStacksTeamStacks = require './homestacksteamstacks'
HomeStacksPrivateStacks = require './homestacksprivatestacks'
HomeStacksDrafts = require './homestacksdrafts'
HomeStacksTabHandle = require './homestackstabhandle'

HomeVirtualMachinesVirtualMachines = require '../virtualmachines/homevirtualmachinesvirtualmachines'
HomeVirtualMachinesConnectedMachines = require '../virtualmachines/homevirtualmachinesconnectedmachines'
HomeVirtualMachinesSharedMachines = require '../virtualmachines/homevirtualmachinessharedmachines'

HomeAccountCredentialsView = require '../account/credentials/homeaccountcredentialsview'
EnvironmentFlux = require 'app/flux/environment'


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

    @tabView.showPane @stacks

    # @tabView.on 'PaneDidShow', (pane) ->
    #   { router } = kd.singletons
    #   path = router.getCurrentPath()
    #   router.handleRoute "/Home/Stacks/#{kd.utils.slugify pane.name}"

    kd.singletons.mainController.ready =>
      @createStacksViews()
      @createVMsViews()
      @createCredentialsViews()


  handleAction: (action) ->

    for pane in @tabView.panes when kd.utils.slugify(pane.name) is action
      pane_ = @tabView.showPane pane
      break




  createStacksViews: ->

    EnvironmentFlux.actions.loadTeamStackTemplates()
    EnvironmentFlux.actions.loadPrivateStackTemplates()

    @stacks.addSubView new HomeStacksCreate

    @stacks.addSubView headerize 'Team Stacks'
    @stacks.addSubView sectionize 'Team Stacks', HomeStacksTeamStacks, { delegate : this }

    @stacks.addSubView headerize 'Private Stacks'
    @stacks.addSubView sectionize 'Private Stacks', HomeStacksPrivateStacks, { delegate : this }

    @stacks.addSubView headerize 'Drafts'
    @stacks.addSubView sectionize 'Drafts', HomeStacksDrafts, { delegate : this }


  createVMsViews: ->

    @vms.addSubView headerize 'Virtual Machines'
    @vms.addSubView sectionize 'Virtual Machines', HomeVirtualMachinesVirtualMachines

    @vms.addSubView headerize 'Connected Machines'
    @vms.addSubView sectionize 'Connected Machines', HomeVirtualMachinesConnectedMachines

    @vms.addSubView headerize 'Shared Machines'
    @vms.addSubView sectionize 'Shared Machines', HomeVirtualMachinesSharedMachines


  createCredentialsViews: ->

    @credentials.addSubView headerize 'Credentials'
    @credentials.addSubView sectionize 'Credentials', HomeAccountCredentialsView