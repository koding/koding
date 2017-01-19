kd = require 'kd'
HomeAddonsTabHandle = require './addonstabhandle'
BusinessAddOnsContainer = require './businessaddons'
SupportPlansContainer = require './supportplans'

module.exports = class AddOns extends kd.CustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'HomeAppView--scroller', options.cssClass

    super options, data

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

    @addOn.addSubView new BusinessAddOnsContainer


  createSupportPlansViews: ->

    @plans.addSubView new SupportPlansContainer
