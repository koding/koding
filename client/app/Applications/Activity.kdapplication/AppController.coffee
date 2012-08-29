class Activity12345 extends AppController

  constructor:(options={})->
    options.view = new KDView cssClass : "content-page activity"
    super options
    CodeSnippetView.on 'CodeSnippetWantsSave', (data)=>
      @saveCodeSnippet data.title, Encoder.htmlDecode data.content

    @currentFilter = [
      'CStatusActivity'
      'CCodeSnipActivity'
      'CFollowerBucketActivity'
      'CNewMemberBucketActivity'
    ]

  saveCodeSnippet:(title, content)->
    # This custom method is used because FS,
    # command, environment are all a mess and
    # devrim is currently working on refactoring them - 3/15/12 sah

    # i kind of cleared that mess, still needs work - 26 April 2012 sinan
    if KD.isLoggedIn()
      @getSingleton('fs').saveToDefaultCodeSnippetFolder '"' + title + '"', content, (error, safeName)->
        if error
          new KDNotificationView
            title    : "Saving the snippet failed with error: #{error}"
            duration : 2500
            type     : 'mini'
        else
          nonEscapedName = safeName.replace /"(.*)"$/, '$1'
          new KDNotificationView
            title    : "Code snippet saved to: #{nonEscapedName}"
            duration : 2500
            type     : 'mini'
    else
      new KDNotificationView
        title    : "Please login!"
        type     : 'mini'
        duration : 2500

  bringToFront:()->
    super name : 'Activity'

  initAndBringToFront:(options,callback)->
    @environment = options.environment
    super

  loadView:(mainView)->

    mainController = @getSingleton('mainController')
    account        = KD.whoami()

    unless localStorage.welcomeMessageClosed?
      mainView.addSubView header = new WelcomeHeader
        type      : "big"
        title     : if KD.isLoggedIn() then "Hi #{account.profile.firstName}! Welcome to the Koding Public Beta." else "Welcome to the Koding Public Beta!"
        subtitle  : ""

    unless account instanceof bongo.api.JGuest
        # subtitle : "Last login #{$.timeago new Date account.meta.modifiedAt}
        # ... where have you been?!" # not relevant for now

      mainView.addSubView updateWidget = new ActivityUpdateWidget
        cssClass: 'activity-update-widget-wrapper'

      updateWidgetController = new ActivityUpdateWidgetController
        view : updateWidget

      updateWidgetController.registerListener
        KDEventTypes  : "OwnActivityHasArrived"
        listener      : @
        callback      : (pubInst,activity)=>
          @ownActivityArrived activity

    # mainView.addSubView new CommonFeedMessage
    #   title           : "<p> Since you're new to Koding, so we've prepared these helper boxes to introduce you to the system. This is your Activity Feed. It displays posts from the people and topics you follow on Koding. It's also the central place for sharing updates, code, links, discussions and questions with the community.</p>"
    #   messageLocation : 'Activity'

    activityInnerNavigation = new ActivityInnerNavigation
    @activityTabView = new KDTabView
      cssClass : "maincontent-tabs feeder-tabs"
    @activityTabView.hideHandleContainer()

    activitySplitView = @activitySplitView = new ActivitySplitView
      views     : [activityInnerNavigation,@activityTabView]
      sizes     : [139,null]
      minimums  : [10,null]
      resizable : no

    # ADD SPLITVIEW
    mainView.addSubView activitySplitView

    @createFollowedAndPublicTabs()

    # INITIAL HEIGHT SET FOR SPLIT
    @utils.wait 1000, =>
      # activitySplitView._windowDidResize()
      mainView.notifyResizeListeners()

    loadIfMoreItemsIsNecessary = =>
      if @activityListController.scrollView.getScrollHeight() <= @activityListController.scrollView.getHeight()
        @continueLoadingTeasers()

    @filter 'public', loadIfMoreItemsIsNecessary

    @getSingleton('activityController').on 'ActivitiesArrived', (activities)=>
      for activity in activities when activity.constructor.name in @currentFilter
        @activityListController.newActivityArrived activity

    activityInnerNavigation.registerListener
      KDEventTypes  : "CommonInnerNavigationListItemReceivedClick"
      listener      : @
      callback      : (pubInst, data)=>
        @filter data.type, loadIfMoreItemsIsNecessary

  ownActivityArrived:(activity)->
    @activityListController.ownActivityArrived activity

  createFollowedAndPublicTabs:->
    # FIRST TAB = FOLLOWED ACTIVITIES, SORT AND POST NEW
    @activityTabView.addPane followedTab = new KDTabPaneView
      cssClass : "activity-content"

    # SECOND TAB = ALL ACTIVITIES, SORT AND POST NEW
    @activityTabView.addPane allTab = new KDTabPaneView
      cssClass : "activity-content"

    @activityListController = activityListController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .75
      subItemClass      : ActivityListItemView

    allTab.addSubView activityListScrollView = activityListController.getView()

    @activitySplitView.on "ViewResized", =>
      newHeight = @activitySplitView.getHeight() - 28 # HEIGHT OF THE HEADER
      activityListController.scrollView.setHeight newHeight

    controller = @

    activityListController.registerListener
      KDEventTypes  : 'LazyLoadThresholdReached'
      listener      : @
      callback      : => @continueLoadingTeasers()

  continueLoadingTeasers:->
    unless @activityListController.isLoading
      @activityListController.isLoading = yes
      @loadSomeTeasers =>
        @activityListController.isLoading = no
        @activityListController.hideLazyLoader()

  fetchTeasers:(selector,options,callback)->
    appManager.fetchStorage 'Activity', '1.0', (err, storage) =>
      if err
        log '>> error fetching app storage', err
      else
        options.collection = 'activities'
        flags = KD.whoami().data.globalFlags
        exempt = flags?.indexOf 'exempt'
        exempt = (exempt? and ~exempt) or storage.getAt 'bucket.showLowQualityContent'
        $.ajax KD.apiUri+'/1.0'
          data      :
            t       : 1 if exempt
            data    : JSON.stringify(_.extend options, selector)
            env     : KD.env
          dataType  : 'jsonp'
          success   : (data)->
            bongo.reviveFromJSONP data, (err, instances)->
              callback instances
    #
    # bongo.api.CActivity.teasers selector, options, (err, activities) =>
    #   if not err and activities?
    #     callback? activities
    #   else
    #     callback()

  fetchFeedForHomePage:(callback)->
    # devrim's api
    # should make the selector work
    selector =
      type      :
        $in     : [
          'CStatusActivity'
          'CCodeSnipActivity'
          'CFolloweeBucketActivity'
          'CNewMemberBucket'
        ]

    options =
      limit         : 7
      skip          : 0
      sort          :
        "createdAt" : -1

    @fetchTeasers selector, options, callback

  loadSomeTeasers:(range, callback)->
    [callback, range] = [range, callback] unless callback
    range or= {}
    {skip, limit} = range

    selector =
      type        :
        $in       : @currentFilter

    options  =
      limit       : limit or= 20
      skip        : skip  or= @activityListController.getItemCount()
      sort        :
        createdAt : -1

    if not options.skip < options.limit
      @fetchTeasers selector, options, (activities)=>
        if activities
          for activity in activities
            @activityListController.addItem activity
          callback? activities
        else
          callback?()

  loadSomeTeasersIn:(sourceIds, options, callback)->
    bongo.api.Relationship.within sourceIds, options, (err, rels)->
      bongo.cacheable rels.map((rel)->
        constructorName : rel.targetName
        id              : rel.targetId
      ), callback

  filter: (show, callback) ->
    controller = @activityListController

    if show is 'private'
      controller._state = 'private'
      controller.itemsOrdered.forEach (item)=>
        item.hide() if not controller.isInFollowing(item.data)
      return no

    else if show is 'public'
      controller._state = 'public'

    else
      @currentFilter = if show? then [show] else [
        'CStatusActivity'
        'CCodeSnipActivity'
        'CFollowerBucketActivity'
        'CNewMemberBucketActivity'
      ]

    controller.removeAllItems()
    controller.showLazyLoader no
    @loadSomeTeasers ->
      controller.isLoading = no
      controller.hideLazyLoader()
      callback?()

  createContentDisplay:(activity)->
    switch activity.bongo_.constructorName
      when "JStatusUpdate" then @createStatusUpdateContentDisplay activity
      when "JCodeSnip"     then @createCodeSnippetContentDisplay activity

  showContentDisplay:(contentDisplay)->
    contentDisplayController = @getSingleton "contentDisplayController"
    contentDisplayController.propagateEvent
      KDEventType : "ContentDisplayWantsToBeShown"
    ,contentDisplay

  createStatusUpdateContentDisplay:(activity)->
    controller = new ContentDisplayControllerActivity
      title       : "Status Update"
      type        : "status"
      contentView : new ContentDisplayStatusUpdate {},activity
    , activity
    contentDisplay = controller.getView()
    @showContentDisplay contentDisplay

  createCodeSnippetContentDisplay:(activity)->
    controller = new ContentDisplayControllerActivity
      title       : "Code Snippet"
      type        : "codesnip"
      contentView : new ContentDisplayCodeSnippet {},activity
    , activity
    contentDisplay = controller.getView()
    @showContentDisplay contentDisplay

class ActivityListController extends KDListViewController

  hiddenItems     = []
  hiddenItemCount = 0

  constructor:(options,data)->
    viewOptions = options.viewOptions or {}
    viewOptions.cssClass      or= 'activity-related'
    viewOptions.comments      or= yes
    viewOptions.subItemClass  or= options.subItemClass
    options.view              or= new KDListView viewOptions, data
    options.startWithLazyLoader = yes
    super

    @_state = 'public'

  loadView:(mainView)->
    data = @getData()
    mainView.addSubView @activityHeader = new ActivityListHeader
      cssClass : 'activityhead clearfix'

    @activityHeader.on "UnhideHiddenNewItems", =>
      top = @getListView().$('.hidden-item').eq(0).position().top
      @scrollView.scrollTo {top, duration : 200}, =>
        unhideNewHiddenItems hiddenItems

    super

    @fetchFollowings()

  fetchFollowings:->
    # To filter followings activites we need to fetch followings data
    KD.whoami()?.fetchFollowingWithRelationship? {}, {}, (err, following)=>
      if err
        log "An error occured while getting followings:", err
        @_following = []
      else
        @_following = following.map((item)-> item._id)

  isMine:(activity)->
    id = KD.whoami().getId()
    id? and id in [activity.originId, activity.anchor?.id]

  isInFollowing:(activity)->
    activity.originId in @_following or activity.anchor?.id in @_following

  ownActivityArrived:(activity)->
    view = @getListView().addHiddenItem activity, 0
    view.addChildView activity, ()=>
      @scrollView.scrollTo {top : 0, duration : 200}, ->
        view.slideIn()

  newActivityArrived:(activity)->
    unless @isMine activity
      if (@_state is 'private' and @isInFollowing activity) or @_state is 'public'
        view = @addHiddenItem activity, 0
        @activityHeader.newActivityArrived()
    else
      switch activity.constructor
        when bongo.api.CFolloweeBucket
          @addItem activity, 0
      @ownActivityArrived activity

  addHiddenItem:(activity, index, animation = null)->
    instance = @getListView().addHiddenItem activity, index, animation
    hiddenItems.push instance
    return instance

  addItem:(activity, index, animation = null) ->
    # log "ADD:", activity
    if (@_state is 'private' and @isInFollowing activity) or @_state is 'public'
      @getListView().addItem activity, index, animation

  unhide = (item)-> item.show()

  unhideNewHiddenItems = (hiddenItems)->
    interval = setInterval ->
      item = hiddenItems.shift()
      if item
        unhide item
      else
        clearInterval interval
    , 177
