class ActivityUpdateWidget extends KDView
  constructor:->
    super
    @windowController = @getSingleton('windowController')
    @listenWindowResize()
    
  setMainSections:->
    @addSubView widgetWrapper = new KDView
      cssClass : 'widget-holder clearfix'

    @addSubView new KDButtonGroupView
      cssClass     : "activity-group"
      buttons      :
        update     :
          icon     : yes
          iconOnly : yes
          iconClass: "update"
          callback : -> log "b"
        codesnip   :
          icon     : yes
          iconOnly : yes
          iconClass: "codesnip"
          callback : -> log "b"
        question   :
          icon     : yes
          iconOnly : yes
          iconClass: "question"
          callback : -> log "c"
        discussion :
          icon     : yes
          iconOnly : yes
          iconClass: "discussion"
          callback : -> log "d"
        tutorial   :
          icon     : yes
          iconOnly : yes
          iconClass: "tutorial"
          callback : -> log "e"
        link       :
          icon     : yes
          iconOnly : yes
          iconClass: "link"
          callback : -> log "f"
    

    # widgetWrapper.addSubView @widgetButton = new WidgetButton @widgetOptions()

    widgetWrapper.addSubView @mainInputTabs = new KDTabView
      height   : "auto"
      cssClass : "update-widget-tabs"

    @mainInputTabs.hideHandleContainer()

    @mainInputTabs.addSubView @gradientBack = new KDCustomHTMLView
      tagName  : 'div'
      cssClass : 'widget-back gradient'

    @listenTo
      KDEventTypes        : 'ReceivedClickElsewhere'
      listenedToInstance  : @mainInputTabs
      callback            : (pubInst,event)=>
        unless $(event.target).closest('.activity-status-context').length > 0
          @windowController.removeLayer @mainInputTabs
          @changeTab "update", "Status Update"

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

    if tabName is 'update'
      @gradientBack.setClass 'gradient'
    else
      @windowController.addLayer @mainInputTabs
      @gradientBack.unsetClass 'gradient'

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
          callback    : (treeItem, event)=> @changeTab "discussion", treeItem.getData().title
        }             
        {             
          title       : "Link"
          type        : "default link disabledForBeta"
          callback    : (treeItem, event)=> @changeTab "link", treeItem.getData().title
        }             
        {             
          title       : "Tutorial"
          type        : "default tutorial disabledForBeta"
          callback    : (treeItem, event)=> @changeTab "tutorial", treeItem.getData().title
        }
      ]
    ]
    callback  : =>
