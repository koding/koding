class ContentDisplayControllerMember extends KDViewController

  constructor:(options={}, data)->
    options = $.extend
      view : mainView = new KDView
        cssClass : 'member content-display'
    ,options
    super options, data

  loadView:(mainView)->
    member = @getData()
    log "asdsd"
    mainView.addSubView subHeader = new KDCustomHTMLView tagName : "h2", cssClass : 'sub-header'
    subHeader.addSubView backLink = new KDCustomHTMLView
      tagName : "a"
      partial : "<span>&laquo;</span> Back"
      click   : (event)->
        event.stopPropagation()
        event.preventDefault()
        contentDisplayController = KD.getSingleton "contentDisplayController"
        contentDisplayController.emit "ContentDisplayWantsToBeHidden", mainView
        history.back()
        no


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

  addActivityView:(account)->

    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', {
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
            KD.getSingleton("appManager").tell 'Activity', 'fetchTeasers', selector, options, (data)->
              callback null, data
        statuses            :
          title             : "Status Updates"
          dataSource        : (selector, options, callback)=>
            selector.originId = account.getId()
            selector.type = 'CStatusActivity'
            KD.getSingleton("appManager").tell 'Activity', 'fetchTeasers', selector, options, (data)->
              callback null, data
        codesnips           :
          title             : "Code Snippets"
          dataSource        : (selector, options, callback)=>
            selector.originId = account.getId()
            selector.type     = 'CCodeSnipActivity'
            KD.getSingleton("appManager").tell 'Activity', 'fetchTeasers', selector, options, (data)->
              callback null, data
        # Discussions Disabled
        # discussions         :
        #   title             : "Discussions"
        #   dataSource        : (selector, options, callback)=>
        #     selector.originId = account.getId()
        #     selector.type     = 'CDiscussionActivity'
        #     KD.getSingleton("appManager").tell 'Activity', 'fetchTeasers', selector, options, (data)->
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

      @getView().addSubView controller.getView()

