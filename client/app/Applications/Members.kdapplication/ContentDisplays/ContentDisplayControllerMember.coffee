class ContentDisplayControllerMember extends KDViewController
  constructor:(options={}, data)->
    options = $.extend
      view : mainView = new KDView
        cssClass : 'member content-display'
    ,options
      
    super options, data
  
  loadView:(mainView)->
    member = @getData()

    # mainView.addSubView header = new HeaderViewSection type : "big", title : "Profile"
    mainView.addSubView subHeader = new KDCustomHTMLView tagName : "h2", cssClass : 'sub-header'
    subHeader.addSubView backLink = new KDCustomHTMLView tagName : "a", partial : "<span>&laquo;</span> Back"

    contentDisplayController = @getSingleton "contentDisplayController"
    
    @listenTo
      KDEventTypes : "click"
      listenedToInstance : backLink
      callback : ()=>
        contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeHidden",mainView
    
    memberProfile = @addProfileView member
    memberStream  = @addActivityView member
    
    # unless KD.isMine member
    #   @listenTo 
    #     KDEventTypes       : "mouseenter"
    #     listenedToInstance : memberProfile
    #     callback           : => @mouseEnterOnHeader()
    
    memberProfile.on 'FollowButtonClicked', @followAccount
    memberProfile.on 'UnfollowButtonClicked', @unfollowAccount
  
  addProfileView:(member)->

    return @getView().addSubView memberProfile = new LoggedOutProfile
      cssClass : "profilearea clearfix"
      bind     : "mouseenter"
      delegate : @getView()
    , member
  
  # mouseEnterOnFeed:->
  # 
  #   clearTimeout @intentTimer
  #   @intentTimer = setTimeout =>
  #     @getView().$('.profilearea').css "overflow", "hidden"
  #     @getView().setClass "small-header"
  #     @utils.nextTick 300,=>
  #       @getSingleton('windowController').notifyWindowResizeListeners()
  #   , 500
  # 
  # mouseEnterOnHeader:->
  # 
  #   clearTimeout @intentTimer
  #   @intentTimer = setTimeout =>
  #     @getView().unsetClass "small-header"
  #     @utils.nextTick 300,=>
  #       @getSingleton('windowController').notifyWindowResizeListeners()
  #       @getView().$('.profilearea').css "overflow", "visible"
  #   , 500
  
  followAccount:(account, callback)->
    account.follow callback
  
  unfollowAccount:(account,callback)->
    account.unfollow callback
    
  addActivityView:(account)->
    appManager.tell 'Feeder', 'createContentFeedController', {
      subItemClass          : ActivityListItemView
      listControllerClass   : ActivityListController
      limitPerPage          : 20
      help                  :
        subtitle            : "Learn Personal feed" 
        tooltip             :
          title             : "<p class=\"bigtwipsy\">This is the personal feed of a single Koding user.</p>"
          placement         : "above"
      filter                :
        Activity            :
          title             : "Activity"
          dataSource        : (selector, options, callback)=>

      sort                  :
        '*'                 :
          title             : "Everything"
          direction         : -1
        'JStatusUpdate'     :
          title             : "Status Updates"
          direction         : -1
        'JCodeSnippet'      :
          title             : "Code Snippets"
          direction         : -1
        # and more
    }, (controller)=>
      #put listeners here, look for the other feeder instances
      
      # unless KD.isMine account
      #   @listenTo 
      #     KDEventTypes       : "mouseenter"
      #     listenedToInstance : controller.getView()
      #     callback           : => @mouseEnterOnFeed()

      @getView().addSubView controller.getView()
    