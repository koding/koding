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
    subHeader.addSubView backLink = new KDCustomHTMLView
        tagName : "a"
        partial : "<span>&laquo;</span> Back"
        click: -> console.log history; history.back(); no

    contentDisplayController = @getSingleton "contentDisplayController"

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : backLink
      callback : (pubInst, event)=>
        event.stopPropagation()
        event.preventDefault()
        contentDisplayController.emit "ContentDisplayWantsToBeHidden", mainView

    # FIX THIS GG

    # @updateWidget = new ActivityUpdateWidget
    #   cssClass: 'activity-update-widget-wrapper-folded'

    # @updateWidgetController = new ActivityUpdateWidgetController
    #   view : @updateWidget

    # mainView.addSubView @updateWidget

    # if not contentDisplayController._updateController
    #   contentDisplayController._updateController = {}
    #   contentDisplayController._updateController.updateWidget = new ActivityUpdateWidget
    #     cssClass: 'activity-update-widget-wrapper-folded'

    #   contentDisplayController._updateController.updateWidgetController = new ActivityUpdateWidgetController
    #     view : contentDisplayController._updateController.updateWidget

    # mainView.addSubView contentDisplayController._updateController.updateWidget

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

    if KD.isMine member

      @getView().addSubView memberProfile = new OwnProfileView {cssClass : "profilearea clearfix",delegate : @getView()}, member
      return memberProfile

    else
      return @getView().addSubView memberProfile = new ProfileView
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
  #     @utils.wait 300,=>
  #       @getSingleton('windowController').notifyWindowResizeListeners()
  #   , 500
  #
  # mouseEnterOnHeader:->
  #
  #   clearTimeout @intentTimer
  #   @intentTimer = setTimeout =>
  #     @getView().unsetClass "small-header"
  #     @utils.wait 300,=>
  #       @getSingleton('windowController').notifyWindowResizeListeners()
  #       @getView().$('.profilearea').css "overflow", "visible"
  #   , 500

  followAccount:(account, callback)->
    account.follow callback

  unfollowAccount:(account,callback)->
    account.unfollow callback

  addActivityView:(account)->

    appManager.tell 'Feeder', 'createContentFeedController', {
      itemClass          : ActivityListItemView
      listControllerClass   : ActivityListController
      listCssClass          : "activity-related"
      limitPerPage          : 8
      help                  :
        subtitle            : "Learn Personal feed"
        tooltip             :
          title             : "<p class=\"bigtwipsy\">This is the personal feed of a single Koding user.</p>"
          placement         : "above"
      filter                :
        everything          :
          title             : "Everything"
          dataSource        : (selector, options, callback)=>
            selector.originId = account.getId()
            selector.type = $in: [
              'CStatusActivity', 'CCodeSnipActivity'
              'CFolloweeBucketActivity', 'CNewMemberBucket'
              'CDiscussionActivity',"CTutorialActivity"
            ]
            appManager.tell 'Activity', 'fetchTeasers', selector, options, (data)->
              callback null, data
        statuses            :
          title             : "Status Updates"
          dataSource        : (selector, options, callback)=>
            selector.originId = account.getId()
            selector.type = 'CStatusActivity'
            appManager.tell 'Activity', 'fetchTeasers', selector, options, (data)->
              callback null, data
        codesnips           :
          title             : "Code Snippets"
          dataSource        : (selector, options, callback)=>
            selector.originId = account.getId()
            selector.type     = 'CCodeSnipActivity'
            appManager.tell 'Activity', 'fetchTeasers', selector, options, (data)->
              callback null, data
        # Discussions Disabled
        # discussions         :
        #   title             : "Discussions"
        #   dataSource        : (selector, options, callback)=>
        #     selector.originId = account.getId()
        #     selector.type     = 'CDiscussionActivity'
        #     appManager.tell 'Activity', 'fetchTeasers', selector, options, (data)->
        #       callback null, data

      sort                  :
        'sorts.likesCount'  :
          title             : "Most popular"
          direction         : -1
        'modifiedAt'        :
          title             : "Latest activity"
          direction         : -1
        'sorts.repliesCount':
          title             : "Most activity"
          direction         : -1
        # and more
    }, (controller)=>
      #put listeners here, look for the other feeder instances

      # unless KD.isMine account
      #   @listenTo
      #     KDEventTypes       : "mouseenter"
      #     listenedToInstance : controller.getView()
      #     callback           : => @mouseEnterOnFeed()
      # log controller
      @getView().addSubView controller.getView()

