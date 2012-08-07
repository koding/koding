class ContentDisplayControllerActivity extends KDViewController
  constructor:(options={}, data)->
    options = $.extend
      title       : "Activity"
      type        : "activity"
      view        : new KDScrollView
        cssClass  : 'content-display activity-related'
      contentView : new KDView
    ,options
    options.contentView.setData data
    super options, data
  
  loadView:(mainView)->
    activity = @getData()

    mainView.addSubView header = new HeaderViewSection type : "big", title : @getOptions().title
    mainView.addSubView subHeader = new KDCustomHTMLView tagName : "h2", cssClass : 'sub-header'
    subHeader.addSubView backLink = new KDCustomHTMLView tagName : "a", partial : "<span>&laquo;</span> Back"
    
    contentDisplayController = @getSingleton "contentDisplayController"
    
    @listenTo
      KDEventTypes : "click"
      listenedToInstance : backLink
      callback : ()=>
        contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeHidden",mainView

    contentView = @getOptions().contentView
    contentView.setDelegate @getView()
    contentView.setClass 'content-display-main-section'
    

    @getView().setClass @getOptions().type
    @getView().addSubView contentView
    
    
    # disabled for beta
    # @getView().addSubView metaSection = new KDView cssClass : "content-display-meta"
    # metaSection.addSubView meta = new ContentDisplayScoreBoard cssClass : "scoreboard",activity
    # metaSection.addSubView tagHead = new KDHeaderView title : "Tags"
    # metaSection.addSubView metaTags = new ContentDisplayTags