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
    memberStream = @addActivityView member
    
    memberProfile.on 'FollowButtonClicked', @followAccount
    memberProfile.on 'UnfollowButtonClicked', @unfollowAccount
  
  addProfileView:(member)->
    @getView().addSubView memberProfile = new LoggedOutProfile {cssClass : "profilearea clearfix",delegate : @getView()}, member
    memberProfile
    
  followAccount:(account, callback)->
    account.follow callback
  
  unfollowAccount:(account,callback)->
    account.unfollow callback
    
  addActivityView:(account)->
