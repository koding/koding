class ActivityUpdateWidget extends KDView

  constructor:(options = {}, data)->

    options.domId    = "activity-update-widget"
    options.cssClass = "activity-update-widget-wrapper"

    super options, data

    @windowController = KD.getSingleton('windowController')
    @listenWindowResize()

  setMainSections:->
    @updatePartial ''
    @addSubView widgetWrapper = new KDView
      cssClass : 'widget-holder clearfix'

    widgetWrapper.addSubView @widgetButton = new WidgetButton @widgetOptions()

    widgetWrapper.addSubView @mainInputTabs = new KDTabView
      height   : "auto"
      cssClass : "update-widget-tabs"

    @mainInputTabs.hideHandleContainer()

    @on "WidgetTabChanged", (tabName)=>
      @windowController.addLayer @mainInputTabs

    @mainInputTabs.on "ResetWidgets", (isHardReset) => @resetWidgets isHardReset

    @mainInputTabs.on 'ReceivedClickElsewhere', (event)=>
      unless $(event.target).closest('.activity-status-context').length > 0

        # if there is a modal present, it MIGHT be used to enter
        # large amounts of text   --arvid
        unless $(event.target).closest('.kdmodal').length > 0
          @resetWidgets()

  resetWidgets: (isHardReset) ->
    @windowController.removeLayer @mainInputTabs
    @unsetClass "edit-mode"
    @changeTab "update", "Status Update"
    @mainInputTabs.emit "MainInputTabsReset", isHardReset

    @_windowDidResize()

  addWidgetPane:(options)->

    {paneName,mainContent} = options

    @mainInputTabs.addPane main = new KDTabPaneView
      name : paneName
    main.addSubView mainContent if mainContent?
    return main

  changeTab:(tabName, title)->

    @showPane tabName
    @_windowDidResize()
    @emit "WidgetTabChanged", tabName

  showPane:(paneName)->

    @mainInputTabs.showPane @mainInputTabs.getPaneByName paneName

  viewAppended:->
    @setMainSections()
    super

  _windowDidResize:->

    width = @getWidth()
    @$('.form-headline, form.status-update-input').width width - 185

  widgetOptions:->
    delegate          : @
    items             :
      "Status Update" :
        type          : "update"
      "Blog Post"     :
        type          : "blogpost"
      "Code Snip"     :
        type          : "codesnip"
      "Discussion"    :
        type          : "discussion"
        disabled      : yes
      "Tutorial"      :
        type          : "tutorial"
        disabled      : yes
