kd = require 'kd'
sectionize = require '../commons/sectionize'
headerize = require '../commons/headerize'

HomeStacksCreate = require './homestackscreate'
HomeStacksTeamStacks = require './homestacksteamstacks'
HomeStacksPrivateStacks = require './homestacksprivatestacks'
HomeStacksDrafts = require './homestacksdrafts'

EnvironmentFlux         = require 'app/flux/environment'


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

    @tabView.unsetClass 'kdscrollview'

    @tabView.addPane @stacks      = new kd.TabPaneView { title: 'Stacks', name: 'List' }
    @tabView.addPane @vms         = new kd.TabPaneView { title: 'Virtual Machines', name: 'VMs' }
    @tabView.addPane @credentials = new kd.TabPaneView { title: 'Credentials', name: 'Credentials' }

    @tabView.showPane @stacks

    kd.singletons.mainController.ready =>
      @createStacksViews()


  createStacksViews: ->

    EnvironmentFlux.actions.loadTeamStackTemplates()
    EnvironmentFlux.actions.loadPrivateStackTemplates()

    @stacks.addSubView new HomeStacksCreate

    @stacks.addSubView headerize 'Team Stacks'
    @stacks.addSubView sectionize 'Team Stacks', HomeStacksTeamStacks

    @stacks.addSubView headerize 'Private Stacks'
    @stacks.addSubView sectionize 'Private Stacks', HomeStacksPrivateStacks

    @stacks.addSubView headerize 'Drafts'
    @stacks.addSubView sectionize 'Drafts', HomeStacksDrafts





