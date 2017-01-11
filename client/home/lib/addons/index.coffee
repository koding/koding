kd = require 'kd'
sectionize = require '../commons/sectionize'
headerize = require '../commons/headerize'
TeamFlux = require 'app/flux/teams'
HomeAddonsTabHandle = require './addonstabhandle'
HomeAddOnBusinessAddOnBanner = require './homeaddonsbusinessaddonbanner'
BusinessAddOnSupportPlansBanner = require './components/businessaddonsupportplansbanner'
SupportPlansBanner = require './components/supportplansbanner'
SupportPlansBusinessAddOnBanner = require './components/supportplansbusinessaddonbanner'
HomeAddOnSupportPlans = require './homeaddonsupportplans'
HomeBusinessAddOnDeactivation = require './homebusinessaddondeactivation'
HomeSupportPlanDeactivation = require './homesupportplandeactivation'
HomeAddOnKodingButton = require './homeaddonkodingbutton'
HomeAddOnIntercom = require './homeaddonintercom'
HomeAddOnChatlio = require './homeaddonchatlio'

module.exports = class AddOns extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

    TeamFlux.actions.loadTeam()
    team = kd.singletons.groupsController.getCurrentGroup()
    @canEdit = kd.singletons.groupsController.canEditGroup()
    @allowedDomains = team.allowedDomains

    @addSubView @topNav  = new kd.TabHandleContainer

    @wrapper.addSubView @tabView = new kd.TabView
      maxHandleWidth       : 'none'
      hideHandleCloseIcons : yes
      detachPanes          : no
      tabHandleContainer   : @topNav
      tabHandleClass       : HomeAddonsTabHandle

    @tabView.unsetClass 'kdscrollview'

    @tabView.addPane @addOn = new kd.TabPaneView { name: 'Business Add-On' }
    @tabView.addPane @plans = new kd.TabPaneView { name: 'Support Plans' }

    @tabView.showPane @addOn

    { mainController, computeController, reactor } = kd.singletons

    mainController.ready =>
      @createBusinessAddonViews()
      @createSupportPlansViews()


  handleAction: (action, query) ->

    { onboarding } = kd.singletons

    for pane in @tabView.panes when kd.utils.slugify(pane.name) is action

      @tabView.showPane pane

      switch action
        when 'business-add-on'
          onboarding.run 'BusinessAddOnViewed', yes
        when 'support-plans'
          onboarding.run 'SupportPlansViewed', yes

      if (Object.keys query).length
        pane.mainView?.handleQuery? query

      break


  createBusinessAddonViews: ->

    @addOn.addSubView sectionize 'Business Add On Banner', HomeAddOnBusinessAddOnBanner

    if '*' in @allowedDomains or @canEdit
      @addOn.addSubView headerize  'Koding Button'
      @addOn.addSubView sectionize 'Koding Button', HomeAddOnKodingButton

    @addOn.addSubView headerize 'Intercom'
    @addOn.addSubView sectionize 'Intercom Integration', HomeAddOnIntercom

    @addOn.addSubView headerize 'Chatlio'
    @addOn.addSubView sectionize 'Customer Feedback', HomeAddOnChatlio

    @addOn.addSubView sectionize 'Business Add On Support Plans Banner', BusinessAddOnSupportPlansBanner

    @addOn.addSubView sectionize 'Business Add On Deactivation', HomeBusinessAddOnDeactivation


  createSupportPlansViews: ->

    @plans.addSubView sectionize 'Support Plans Banner', SupportPlansBanner

    @plans.addSubView headerize 'Available Plans'
    @plans.addSubView sectionize 'Support Plans Section', HomeAddOnSupportPlans

    @plans.addSubView sectionize 'Support Plans Business Add On Banner', SupportPlansBusinessAddOnBanner
    @plans.addSubView sectionize 'Support Plan Deactivation', HomeSupportPlanDeactivation
