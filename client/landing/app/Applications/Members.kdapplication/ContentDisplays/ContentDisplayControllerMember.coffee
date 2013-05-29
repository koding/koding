class ContentDisplayControllerMember extends KDViewController

  constructor:(options={}, data)->

    {@revivedContentDisplay} = @getSingleton("contentDisplayController")

    options = $.extend
      view : mainView = new KDView
        cssClass : 'member content-display'
        domId : 'member-contentdisplay' unless @revivedContentDisplay
    ,options
    super options, data

  loadView:(mainView)->
    member = @getData()
    {lazy} = mainView
    mainView.addSubView subHeader = new KDCustomHTMLView
      tagName   : "h2"
      cssClass  : 'sub-header'
      domId     : 'members-sub-header' if lazy

    subHeader.addSubView backLink = new KDCustomHTMLView
      domId   : 'members-back-link' if lazy
      tagName : "a"
      partial : "<span>&laquo;</span> Back"
      click   : (event)->
        event.stopPropagation()
        event.preventDefault()
        contentDisplayController = KD.getSingleton "contentDisplayController"
        contentDisplayController.emit "ContentDisplayWantsToBeHidden", mainView
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

    @addProfileView member

    if lazy and not KD.isLoggedIn()
      mainView.addSubView @homeLoginBar = new HomeLoginBar
        domId    : "home-login-bar"

    @addActivityView member

  addProfileView:(member)->
    if KD.isMine member

      @getView().addSubView memberProfile = new OwnProfileView
        cssClass : "profilearea clearfix"
        delegate : @getView()
        domId    : 'profilearea' unless @revivedContentDisplay
      , member
      return memberProfile

    else
      return @getView().addSubView memberProfile = new ProfileView
        cssClass : "profilearea clearfix"
        bind     : "mouseenter"
        domId    : 'profilearea' unless @revivedContentDisplay
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

  createFilter:(title, account, facets)->
    filter =
      title             : title
      dataSource        : (selector, options, callback)=>
        options.originId = account.getId()
        options.facets   = facets
        KD.getSingleton("appManager").tell 'Activity', 'fetchTeasers', options, callback
    return filter

  addActivityView:(account)->

    @getView().$('div.lazy').remove()


    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', {
      domId                 : 'members-feeder-split-view' unless @revivedContentDisplay
      itemClass             : ActivityListItemView
      listControllerClass   : ActivityListController
      listCssClass          : "activity-related"
      limitPerPage          : 8
      help                  :
        subtitle            : "Learn Personal feed"
        tooltip             :
          title             : "<p class=\"bigtwipsy\">This is the personal feed of a single Koding user.</p>"
          placement         : "above"
      filter                :
        everything          : @createFilter("Everything", account,
          [ 'CStatusActivity', 'CCodeSnipActivity', 'CFolloweeBucketActivity', 'CNewMemberBucket'
          'CDiscussionActivity',"CTutorialActivity", "CBlogPostActivity" ])
        statuses            : @createFilter("Status Updates", account, ['CStatusActivity'])
        codesnips           : @createFilter("Code Snippets", account, ['CCodeSnipActivity'])
        blogposts           : @createFilter("Blog Posts", account, ['CBlogPostActivity'])
        discussions         : @createFilter("Discussions", account, ['CDiscussionActivity'])
        tutorials           : @createFilter("Tutorials", account, ['CTutorialActivity'])
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
      @feedController = controller
      @getView().addSubView controller.getView()
      @emit 'ready'