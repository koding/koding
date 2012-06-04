class ActivityUpdateWidgetController extends KDViewController
  loadView:(mainView)->
    controller = @
    # TODO: What's with the _unc? (Unhelpful Naming Convention) C.T.

    _asuw = new ActivityStatusUpdateWidget
      cssClass : "status-update-input"
      
    
    mainView.registerListener
      KDEventTypes  : "AutoCompleteNeedsTagData"
      listener      : @
      callback      : (pubInst,event)=> 
        {callback,inputValue,blacklist} = event
        @fetchAutoCompleteDataForTags inputValue,blacklist,callback
    
    mainView.addWidgetPanes
      paneName    : "update"
      mainContent : _asuw
    _asuw.formSetCallback (formData)=>
      _asuw.input.setValue ''
      @updateWidgetSubmit formData

    mainView.addWidgetPanes
      paneName    : "question"
      mainContent : _aqw = new ActivityQuestionWidget 
        callback  : @questionWidgetSubmit

    codeSnippetPane = mainView.addWidgetPanes
      paneName    : "codesnip"
      mainContent : _acsw = new ActivityCodeSnippetWidget 
        callback  : (data)->
          controller.codeSnippetWidgetSubmit data, (success)=>
            @reset() if success
        delegate  : mainView

    mainView.addWidgetPanes
      paneName    : "link"
      mainContent : _alw = new ActivityLinkWidget 
        callback  : @linkWidgetSubmit

    mainView.addWidgetPanes
      paneName    : "tutorial"
      mainContent : _atw = new ActivityTutorialWidget 
        callback  : @tutorialWidgetSubmit

    mainView.addWidgetPanes
      paneName    : "discussion"
      mainContent : _atw = new ActivityDiscussionWidget 
        callback  : @discussionWidgetSubmit

    mainView.showPane "update"

    codeSnippetPane.registerListener KDEventTypes : 'PaneDidShow', listener : @, callback : -> _acsw.widgetShown()


  updateWidgetSubmit:(data)->

    bongo.api.JStatusUpdate.create data, (err,activity)=>
      unless err
        @propagateEvent (KDEventType:"OwnActivityHasArrived"), activity
      else
        new KDNotificationView title : "There was an error, try again later!"

    #bongo.api.JActivity.create {type: 'status', activity: data}, (error) ->
    #  warn 'couldnt save status', error if error

  codeSnippetWidgetSubmit:(data, callback)->

    bongo.api.JCodeSnip.create data, (err,codesnip) =>

      unless err
        @propagateEvent (KDEventType:"OwnActivityHasArrived"), codesnip
        callback yes
      else
        new KDNotificationView title : "There was an error, try again later!"
        callback no
    return @

  questionWidgetSubmit:(data)->
    log 'creating question', data
    bongo.api.JActivity.create {type: 'qa', activity: data}, (error) ->
      warn 'couldnt ask question', error if error
  
  linkWidgetSubmit:(data)->
    log 'sharing link', data
    bongo.api.JActivity.create {type: 'link', activity: data}, (error) ->
      warn 'couldnt save link', error if error

  tutorialWidgetSubmit:(data)->
    log 'sharing tutorial', data
    bongo.api.JActivity.create {type: 'tutorial', activity: data}, (error) ->
      warn 'couldnt save tutorial', error if error

  discussionWidgetSubmit:(data)->
    log 'starting discussion', data
    bongo.api.JActivity.create {type: 'discussion', activity: data}, (error) ->
      warn 'couldnt save discussion', error if error

  fetchAutoCompleteDataForTags:(inputValue,blacklist,callback)->
    bongo.api.JTag.byRelevance inputValue, {blacklist}, (err,tags)->
      unless err
        callback? tags
      else
        log "there was an error fetching topics"



class ActivityUpdateWidget extends KDView
  constructor:->
    super
    @windowController = @getSingleton('windowController')
    @listenWindowResize()
    
  setMainSections:->
    @addSubView widgetWrapper = new KDView
      cssClass : 'widget-holder clearfix'

    widgetWrapper.addSubView widgetButtonForStatusSelection = new WidgetButtonForStatusSelection
      delegate : @

    widgetWrapper.addSubView @mainInputTabs = new KDTabView height : "auto",cssClass : "update-widget-tabs"
    @mainInputTabs.hideHandleContainer()

    @mainInputTabs.addSubView @gradientBack = new KDCustomHTMLView
      tagName : 'div'
      cssClass : 'widget-back gradient'

    @listenTo
      KDEventTypes : "changeAddActivityWidget"
      listenedToInstance : widgetButtonForStatusSelection
      callback : @changeTabs

    @listenTo
      KDEventTypes        : 'ReceivedClickElsewhere'
      listenedToInstance  : @mainInputTabs
      callback            : (pubInst,event)=>
        unless $(event.target).closest('.activity-status-context').length > 0
          @windowController.removeLayer @mainInputTabs
          @handleEvent type : "ActivityUpdateWidgetShouldReset"

  addWidgetPanes:(options)->
    {paneName,mainContent} = options
    
    @mainInputTabs.addPane main = new KDTabPaneView name : paneName 
    main.addSubView mainContent if mainContent?
    return main

  changeTabs:(pubInst,event)->
    @showPane event.tabName
    @resizeContents()
    if event.tabName is 'update'
      @gradientBack.setClass 'gradient'
    else
      @windowController.addLayer @mainInputTabs
      @gradientBack.unsetClass 'gradient'

  resizeContents:->
    width = @getWidth()
    @$('.form-headline, form.status-update-input').width width - 185
    # @$('.formline').width width - 185

  showPane:(paneName)->
    #shows default panes 
    @mainInputTabs.showPane @mainInputTabs.getPaneByName paneName
  
  viewAppended:->
    @setMainSections()
    super
  
  _windowDidResize:->
    @resizeContents()