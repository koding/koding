class ActivityUpdateWidget extends KDView

  constructor:(options = {}, data)->

    options.cssClass = "activity-update-widget-wrapper"

    super options, data

    @windowController = @getSingleton('windowController')
    @listenWindowResize()

  setMainSections:->

    @addSubView widgetWrapper = new KDView
      cssClass : 'widget-holder clearfix'

    widgetWrapper.addSubView @widgetButton = new WidgetButton @widgetOptions()

    widgetWrapper.addSubView @mainInputTabs = new KDTabView
      height   : "auto"
      cssClass : "update-widget-tabs"

    @mainInputTabs.hideHandleContainer()

    @on "WidgetTabChanged", (tabName)=>
      @windowController.addLayer @mainInputTabs

    @mainInputTabs.on "ResetWidgets", => @resetWidgets()

    @mainInputTabs.on 'ReceivedClickElsewhere', (event)=>
      unless $(event.target).closest('.activity-status-context').length > 0

        # if there is a modal present, it MIGHT be used to enter
        # large amounts of text   --arvid
        unless $(event.target).closest('.kdmodal').length > 0
          @resetWidgets()

  resetWidgets:->

    @windowController.removeLayer @mainInputTabs
    @unsetClass "edit-mode"
    @changeTab "update", "Status Update"
    @mainInputTabs.emit "MainInputTabsReset"
    @_windowDidResize()

  addWidgetPane:(options)->

    {paneName,mainContent} = options

    @mainInputTabs.addPane main = new KDTabPaneView
      name : paneName
    main.addSubView mainContent if mainContent?
    return main

  changeTab:(tabName, title)->

    @showPane tabName
    @widgetButton.decorateButton tabName, title
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

    title             : "Status Update"
    style             : "activity-status-context"
    icon              : yes
    iconClass         : "update"
    delegate          : @

    menu              :
      "Status Update" :
        type          : "update"
        callback      : (treeItem, event)=> @changeTab "update", treeItem.getData().title
      "Blog Post":
        type          : "blogpost"
        callback      : (treeItem, event)=> @changeTab "blogpost", treeItem.getData().title
      "Code Snip"     :
        type          : "codesnip"
        callback      : (treeItem, event)=> @changeTab "codesnip", treeItem.getData().title
      # "Code Share"    :
      #   type          : "codeshare"
      #   disabled      : no
      #   callback      : (treeItem, event)=> @changeTab "codeshare", treeItem.getData().title
      "Discussion"    :
        type          : "discussion"
        disabled      : no
        callback      : (treeItem, event)=> @changeTab "discussion", treeItem.getData().title
      # "Link"          :
      #   disabled      : no
      #   type          : "link"
      #   callback      : (treeItem, event)=> @changeTab "link", treeItem.getData().title
      "Tutorial"      :
        type          : "tutorial"
        disabled      : no
        callback      : (treeItem, event)=> @changeTab "tutorial", treeItem.getData().title
    callback          : =>
