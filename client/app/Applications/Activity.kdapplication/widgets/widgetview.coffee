class ActivityUpdateWidget extends KDView

  constructor:->

    super
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

    @listenTo
      KDEventTypes        : 'ReceivedClickElsewhere'
      listenedToInstance  : @mainInputTabs
      callback            : (pubInst,event)=>
        unless $(event.target).closest('.activity-status-context').length > 0
          @resetWidgets()

  resetWidgets:->

    @unsetClass "edit-mode"
    @windowController.removeLayer @mainInputTabs
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
    menu              : [
      items           : [
        {
          title       : "Status Update"
          type        : "default update"
          callback    : (treeItem, event)=> @changeTab "update", treeItem.getData().title
        }
        {
          title       : "Ask a Question"
          type        : "default question disabledForBeta"
          disabled    : yes
          callback    : (treeItem, event)=> @changeTab "question", treeItem.getData().title
        }             
        {             
          title       : "Code Snip"
          type        : "default codesnip"
          callback    : (treeItem, event)=> @changeTab "codesnip", treeItem.getData().title
        }             
        {             
          title       : "Start a Discussion"
          type        : "default discussion disabledForBeta"
          disabled    : yes
          callback    : (treeItem, event)=> @changeTab "discussion", treeItem.getData().title
        }             
        {             
          title       : "Link"
          disabled    : yes
          type        : "default link disabledForBeta"
          callback    : (treeItem, event)=> @changeTab "link", treeItem.getData().title
        }             
        {             
          title       : "Tutorial"
          type        : "default tutorial disabledForBeta"
          disabled    : yes
          callback    : (treeItem, event)=> @changeTab "tutorial", treeItem.getData().title
        }
      ]
    ]
    callback  : =>
