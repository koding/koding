class ActivityAppController extends AppController

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
      # 'COpinionActivity'
      # THIS WILL DISABLE CODE SHARES/LINKS/DISCUSSIONS
      'CDiscussionActivity'
      'CTutorialActivity'
      # 'CLinkActivity'
      # 'CCodeShareActivity'
      'CInstallerBucketActivity'
    ]

  saveCodeSnippet:(title, content)->
    # This custom method is used because FS,
    # command, environment are all a mess and
    # devrim is currently working on refactoring them - 3/15/12 sah

    # i kind of cleared that mess, still needs work - 26 April 2012 sinan
    # remove this shit, do it with kitecontroller :) - 8 October 2012 sinan
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

  loadView:(mainView)->

    mainController = @getSingleton('mainController')
    account        = KD.whoami()

    # mainController.popupController = new VideoPopupController

    unless localStorage.welcomeMessageClosed?
      mainView.addSubView mainView.header = new WelcomeHeader
        type      : "big"
        title     : if KD.isLoggedIn() then\
          "Hi #{account.profile.firstName}! Welcome to the Koding Public Beta." else\
          "Welcome to the Koding Public Beta!<br>"
        subtitle  : "Warning! when we say beta - <a href='#'>we mean it</a> :)"

    if KD.isLoggedIn()
      @putWidget()
    else
      @getSingleton("mainController").once "AccountChanged", @putWidget.bind @

    # mainView.addSubView new CommonFeedMessage
    #   title           : "<p> Since you're new to Koding, so we've prepared these helper boxes to introduce you to the system. This is your Activity Feed. It displays posts from the people and topics you follow on Koding. It's also the central place for sharing updates, code, links, discussions and questions with the community.</p>"
    #   messageLocation : 'Activity'

    activityInnerNavigation = new ActivityInnerNavigation
    @activityTabView = new KDTabView
      cssClass : "maincontent-tabs feeder-tabs"
    @activityTabView.hideHandleContainer()

    mainView.activitySplit = new ActivitySplitView
      views     : [activityInnerNavigation,@activityTabView]
      sizes     : [139,null]
      minimums  : [10,null]
      resizable : no
      delegate  : mainView


    # ADD SPLITVIEW
    mainView.addSubView mainView.activitySplit

    @createFollowedAndPublicTabs()

    account.on "FollowedActivityArrived", (activityId) =>
      KD.remote.api.CActivity.one {_id: activityId}, (err, activity) =>
        if activity.constructor.name in @currentFilter
          activity.snapshot?.replace /&quot;/g, '"'
          @activityListController.followedActivityArrived activity

    # INITIAL HEIGHT SET FOR SPLIT
    @utils.wait 1000, =>
      # @getView().activitySplit._windowDidResize()
      mainView.notifyResizeListeners()

    loadIfMoreItemsIsNecessary = =>
      if @activityListController.scrollView.getScrollHeight() <= @activityListController.scrollView.getHeight()
        @continueLoadingTeasers()

    @filter 'public', loadIfMoreItemsIsNecessary

    @getSingleton('activityController').on 'ActivitiesArrived', (activities)=>
      for activity in activities when activity.constructor.name in @currentFilter
        @activityListController.newActivityArrived activity

    activityInnerNavigation.on "NavItemReceivedClick", (data)=>
      @filter data.type, loadIfMoreItemsIsNecessary

  putWidget : ->

    mainView = @getView()

    mainView.addSubView mainView.widget = new ActivityUpdateWidget
      cssClass: 'activity-update-widget-wrapper'

    updateWidgetController = new ActivityUpdateWidgetController
      view : mainView.widget

    updateWidgetController.registerListener
      KDEventTypes  : "OwnActivityHasArrived"
      listener      : @
      callback      : (pubInst,activity)=>
        @ownActivityArrived activity

    return updateWidgetController


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
      itemClass         : ActivityListItemView

    allTab.addSubView activityListScrollView = activityListController.getView()

    {activitySplit} = @getView()
    activitySplit.on "ViewResized", ->
      newHeight = activitySplit.getHeight() - 28 # HEIGHT OF THE HEADER
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

  performFetchingTeasers:(type, selector, options, callback) ->
    if type is 'public'
      appManager.fetchStorage 'Activity', '1.0', (err, storage) =>
        if err
          log '>> error fetching app storage', err
        else
          options.collection = 'activities'
          flags = KD.whoami().globalFlags
          exempt = flags?.indexOf 'exempt'
          exempt = (exempt? and ~exempt) or storage.getAt 'bucket.showLowQualityContent'
          $.ajax KD.apiUri+'/1.0'
            data      :
              t       : if exempt then 1 else undefined
              data    : JSON.stringify(_.extend options, selector)
              env     : KD.config.env
            dataType  : 'jsonp'
            success   : (data) -> callback null, data
          # unless exempt
          #   selector['isLowQuality'] = {'$ne':yes}
          # KD.remote.api.CActivity.some selector, options, (err, data) ->
          #   if err
          #     callback err
          #   else
          #     for datum in data
          #       datum.snapshot = datum.snapshot?.replace /&quot;/g, '"'
          #     callback null, data

    else if type is 'private'
      KD.whoami().fetchFeedByTitle "followed", (err, feed) ->
        feed.fetchActivities selector, options, (err, data) ->
          if err
            callback err
          else
            for datum in data
              datum.snapshot = datum.snapshot.replace /&quot;/g, '"'
            callback null, data

  fetchTeasers:(selector,options,callback)->
    type = @activityListController?._state
    @performFetchingTeasers type, selector, options, (err, data) ->
      KD.remote.reviveFromSnapshots data, (err, instances)->
        callback instances

    # # Old code
    #
    # appManager.fetchStorage 'Activity', '1.0', (err, storage) =>
    #   if err
    #     log '>> error fetching app storage', err
    #   else
    #     options.collection = 'activities'
    #     flags = KD.whoami().globalFlags
    #     exempt = flags?.indexOf 'exempt'
    #     exempt = (exempt? and ~exempt) or storage.getAt 'bucket.showLowQualityContent'
    #     $.ajax KD.apiUri+'/1.0'
    #       data      :
    #         t       : if exempt then 1 else undefined
    #         data    : JSON.stringify(_.extend options, selector)
    #         env     : KD.config.env
    #       dataType  : 'jsonp'
    #       success   : (data)->
    #         KD.remote.reviveFromSnapshots data, (err, instances)->
    #           # log instances
    #           callback instances

    # # Unused code from before
    #
    # KD.remote.api.CActivity.teasers selector, options, (err, activities) =>
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
          # 'COpinionActivity'
          # THIS WILL DISABLE CODE SHARES/LINKS/DISCUSSIONS
          'CDiscussionActivity'
          'CTutorialActivity'
          # 'CLinkActivity'
          # 'CCodeShareActivity'
          'CInstallerBucketActivity'
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

    controller = @activityListController

    selector =
      type        :
        $in       : @currentFilter

    options  =
      limit       : limit or= 20
      skip        : skip  or= controller.getItemCount()
      sort        :
        createdAt : -1

    if not options.skip < options.limit
      @fetchTeasers selector, options, (activities)=>
        if activities
          for activity in activities when activity?
            controller.addItem activity
          callback? activities
        else
          callback?()

  loadSomeTeasersIn:(sourceIds, options, callback)->
    KD.remote.api.Relationship.within sourceIds, options, (err, rels)->
      KD.remote.cacheable rels.map((rel)->
        constructorName : rel.targetName
        id              : rel.targetId
      ), callback

  filter: (show, callback) ->

    controller = @activityListController
    controller.noActivityItem.hide()

    if show is 'private'
      #_counter = 0
      controller._state = 'private'
      # controller.itemsOrdered.forEach (item)=>
      #   if not controller.isInFollowing(item.data)
      #     item.hide()
      #     _counter++
      # if _counter is controller.itemsOrdered.length
      #   controller.noActivityItem.show()
      # return no

    else if show is 'public'
      controller._state = 'public'

    else
      @currentFilter = if show? then [show] else [
        'CStatusActivity'
        'CCodeSnipActivity'
        'CFollowerBucketActivity'
        'CNewMemberBucketActivity'
        # 'COpinionActivity'
        # THIS WILL DISABLE CODE SHARES/LINKS/DISCUSSIONS
        'CDiscussionActivity'
        'CTutorialActivity'
        # 'CLinkActivity'
        # 'CCodeShareActivity'
        'CInstallerBucketActivity'
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
      # THIS WILL DISABLE CODE SHARES/LINKS/DISCUSSIONS
      when "JDiscussion"   then @createDiscussionContentDisplay activity
      when "JTutorial"     then @createTutorialContentDisplay activity
      # when "JCodeShare"    then @createCodeShareContentDisplay activity
      # when "JLink"         then @createLinkContentDisplay activity


  showContentDisplay:(contentDisplay)->
    contentDisplayController = @getSingleton "contentDisplayController"
    contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay

  createStatusUpdateContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayStatusUpdate
      title : "Status Update"
      type  : "status"
    ,activity

  createLinkContentDisplay:(activity)->
    controller = new ContentDisplayControllerActivity
      title       : "Link"
      type        : "link"
      contentView : new ContentDisplayStatusUpdate {},activity
    , activity
    contentDisplay = controller.getView()
    @showContentDisplay contentDisplay

  createCodeSnippetContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayCodeSnippet
      title : "Code Snippet"
      type  : "codesnip"
    ,activity

  # THIS WILL DISABLE CODE SHARES
  # createCodeShareContentDisplay:(activity)->
  #   @showContentDisplay new ContentDisplayCodeShare
  #     title       : "Code Share"
  #     type        : "codeshare"
  #   , activity

  createDiscussionContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayDiscussion
      title : "Discussion"
      type  : "discussion"
    ,activity

  createTutorialContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayTutorial
      title : "Tutorial"
      type  : "tutorial"
    ,activity

class ActivityListController extends KDListViewController

  hiddenItems     = []
  hiddenItemCount = 0

  constructor:(options,data)->
    viewOptions = options.viewOptions or {}
    viewOptions.cssClass      or= 'activity-related'
    viewOptions.comments      or= yes
    viewOptions.itemClass  or= options.itemClass
    options.view              or= new KDListView viewOptions, data
    options.startWithLazyLoader = yes
    super

    @_state = 'public'

    @scrollView.on 'scroll', (event) =>
      if event.delegateTarget.scrollTop > 10
        @activityHeader.setClass "scrolling-up-outset"
      else
        @activityHeader.unsetClass "scrolling-up-outset"

    @scrollView.addSubView @noActivityItem = new KDCustomHTMLView
      cssClass : "lazy-loader"
      partial  : "There is no activity from your followings."
    @noActivityItem.hide()

  loadView:(mainView)->
    @noActivityItem.hide()

    data = @getData()
    mainView.addSubView @activityHeader = new ActivityListHeader
      cssClass : 'activityhead clearfix'

    @activityHeader.on "UnhideHiddenNewItems", =>
      firstHiddenItem = @getListView().$('.hidden-item').eq(0)
      if firstHiddenItem.length > 0
        top   = firstHiddenItem.position().top
        top or= 0
        @scrollView.scrollTo {top, duration : 200}, =>
          unhideNewHiddenItems hiddenItems
    super

    #@fetchFollowings()

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

  isInFollowing:(activity, callback)->
    account = KD.whoami()
    {originId, anchor} = activity
    account.isFollowing originId, 'JAccount', (result) ->
      if result
        callback true
      else
        activity.fetchTeaser? (err, {tags}) =>
          callback false unless tags?
          tagIds = tags.map((tag) -> tag._id)
          account.isFollowing {$in: tagIds}, 'JTag', (result) ->
            callback result

  # isInFollowing:(activity)->
  #   activity.originId in @_following or activity.anchor?.id in @_following

  ownActivityArrived:(activity)->
    view = @getListView().addHiddenItem activity, 0
    view.addChildView activity, ()=>
      @scrollView.scrollTo {top : 0, duration : 200}, ->
        view.slideIn()

  followedActivityArrived: (activity) ->
    if @_state is 'private'
      view = @addHiddenItem activity, 0
      @activityHeader.newActivityArrived()

  newActivityArrived:(activity)->
    return unless @_state is 'public'
    unless @isMine activity
      view = @addHiddenItem activity, 0
      @activityHeader.newActivityArrived()

    #   if (@_state is 'private' and @isInFollowing activity) or @_state is 'public'
    #     view = @addHiddenItem activity, 0
    #     @activityHeader.newActivityArrived()
    else
      switch activity.constructor
        when KD.remote.api.CFolloweeBucket
          @addItem activity, 0
      @ownActivityArrived activity

  addHiddenItem:(activity, index, animation = null)->
    instance = @getListView().addHiddenItem activity, index, animation
    hiddenItems.push instance
    return instance

  addItem:(activity, index, animation = null) ->
    @noActivityItem.hide()
    # log "ADD:", activity
    @getListView().addItem activity, index, animation

    # if (@_state is 'private' and @isInFollowing activity) or @_state is 'public'
    #   @getListView().addItem activity, index, animation

  unhide = (item)-> item.show()

  unhideNewHiddenItems = (hiddenItems)->
    interval = setInterval ->
      item = hiddenItems.shift()
      if item
        unhide item
      else
        clearInterval interval
    , 177
