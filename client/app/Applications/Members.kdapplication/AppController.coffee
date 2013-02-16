class MembersAppController extends AppController
  constructor:(options, data)->
    options = $.extend
      view : mainView = (new MembersMainView cssClass : "content-page members")
    ,options
    super options,data

  bringToFront:()->
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
      options :
        name : 'Members'
      data : @getView()

  createFeed:(view)->
    appManager.tell 'Feeder', 'createContentFeedController', {
      itemClass             : MembersListItemView
      listControllerClass   : MembersListViewController
      noItemFoundText       : "There is no member."
      limitPerPage          : 10
      help                  :
        subtitle            : "Learn About Members"
        tooltip             :
          title             : "<p class=\"bigtwipsy\">These people are all members of koding.com. Learn more about them and their interests, activity and coding prowess here.</p>"
          placement         : "above"
      filter                :
        everything          :
          title             : "All Members <span class='member-numbers-all'></span>"
          optional_title    : if @_searchValue then "<span class='optional_title'></span>" else null
          dataSource        : (selector, options, callback)=>
            if @_searchValue
              @setCurrentViewHeader "Searching for <strong>#{@_searchValue}</strong>..."
              KD.remote.api.JAccount.byRelevance @_searchValue, options, callback
            else
              KD.remote.api.JAccount.someWithRelationship selector, options, callback
              #{currentDelegate} = @getSingleton('mainController').getVisitor()
              @setCurrentViewNumber 'all'
        followed            :
          title             : "Followers <span class='member-numbers-followers'></span>"
          noItemFoundText   : "There is no member who follows you."
          dataSource        : (selector, options, callback)=>
            KD.whoami().fetchFollowersWithRelationship selector, options, callback
            @setCurrentViewNumber 'followers'
        followings          :
          title             : "Following <span class='member-numbers-following'></span>"
          noItemFoundText   : "You are not following anyone."
          dataSource        : (selector, options, callback)=>
            KD.whoami().fetchFollowingWithRelationship selector, options, callback
            @setCurrentViewNumber 'following'
      sort                  :
        'meta.modifiedAt'   :
          title             : "Latest activity"
          direction         : -1
        'counts.followers'  :
          title             : "Most Followers"
          direction         : -1
        'counts.following'  :
          title             : "Most Following"
          direction         : -1
    }, (controller)=>
      @feedController = controller
      view.addSubView @_lastSubview = controller.getView()
      @emit 'ready'
      controller.on "FeederListViewItemCountChanged", (count, filter)=>
        if @_searchValue and filter is 'everything'
          @setCurrentViewHeader count

  createFeedForContentDisplay:(view, account, followersOrFollowing)->

    appManager.tell 'Feeder', 'createContentFeedController', {
      itemClass             : MembersListItemView
      listControllerClass   : MembersListViewController
      limitPerPage          : 10
      noItemFoundText       : "There is no member."
      # singleDataSource      : (selector, options, callback)=>
        # filterFunc selector, options, callback
      help                  :
        subtitle            : "Learn About Members"
        tooltip             :
          title             : "<p class=\"bigtwipsy\">These people are all members of koding.com. Learn more about them and their interests, activity and coding prowess here.</p>"
          placement         : "above"
      filter                :
        everything          :
          title             : "All"
          dataSource        : (selector, options, callback)=>
            if followersOrFollowing is "followers"
              account.fetchFollowersWithRelationship selector, options, callback
            else
              account.fetchFollowingWithRelationship selector, options, callback
      sort                  :
        'meta.modifiedAt'   :
          title             : "Latest activity"
          direction         : -1
        'counts.followers'  :
          title             : "Most Followers"
          direction         : -1
        'counts.following'  :
          title             : "Most Following"
          direction         : -1
    }, (controller)=>

      view.addSubView controller.getView()
      contentDisplayController = @getSingleton "contentDisplayController"
      contentDisplayController.emit "ContentDisplayWantsToBeShown", view

  createFolloweeContentDisplay:(account, filter)->
    # log "I need to create followee for", account, filter
    newView = (new MembersContentDisplayView cssClass : "content-display #{filter}")
    newView.createCommons(account, filter)
    @createFeedForContentDisplay newView, account, filter

  createLikedFeedForContentDisplay:(view, account)->

    appManager.tell 'Feeder', 'createContentFeedController', {
      itemClass             : ActivityListItemView
      listCssClass          : "activity-related"
      noItemFoundText       : "There is no liked activity."
      limitPerPage          : 8
      help                  :
        subtitle            : "Learn Personal feed"
        tooltip             :
          title             : "<p class=\"bigtwipsy\">This is the liked feed of a single Koding user.</p>"
          placement         : "above"
      filter                :
        everything          :
          title             : "Everything"
          dataSource        : (selector, options, callback)=>
            account.fetchLikedContents options, callback
        statusupdates       :
          title             : 'Status Updates'
          dataSource        : (selector, options, callback)->
            selector = {sourceName: $in: ['JStatusUpdate']}
            account.fetchLikedContents options, selector, callback
        codesnippets        :
          title             : 'Code Snippets'
          dataSource        : (selector, options, callback)->
            selector = {sourceName: $in: ['JCodeSnip']}
            account.fetchLikedContents options, selector, callback
        # Discussions Disabled
        # discussions         :
        #   title             : 'Discussions'
        #   dataSource        : (selector, options, callback)->
        #     selector = {sourceName: $in: ['JDiscussion']}
        #     account.fetchLikedContents options, selector, callback
      sort                :
        'timestamp|new'   :
          title           : 'Latest activity'
          direction       : -1
        'timestamp|old'   :
          title           : 'Most activity'
          direction       : 1
    }, (controller)=>

      view.addSubView controller.getView()
      contentDisplayController = @getSingleton "contentDisplayController"
      contentDisplayController.emit "ContentDisplayWantsToBeShown", view

  createLikedContentDisplay:(account)->
    newView = (new MembersLikedContentDisplayView cssClass : "content-display likes")
    newView.createCommons account
    @createLikedFeedForContentDisplay newView, account

  loadView:(mainView, firstRun = yes)->
    if firstRun
      mainView.on "searchFilterChanged", (value) =>
        return if value is @_searchValue
        @_searchValue = Encoder.XSSEncode value
        @_lastSubview.destroy?()
        @loadView mainView, no
      mainView.createCommons()
    @createFeed mainView

  showMemberContentDisplay:(pubInst, event)=>
    {content} = event
    contentDisplayController = @getSingleton "contentDisplayController"
    controller = new ContentDisplayControllerMember null, content
    contentDisplay = controller.getView()
    contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay

  createContentDisplay:(account, doShow = yes)->
    controller = new ContentDisplayControllerMember null, account
    contentDisplay = controller.getView()
    if doShow
      @showContentDisplay contentDisplay

    return contentDisplay

  showContentDisplay:(contentDisplay)->
    contentDisplayController = @getSingleton "contentDisplayController"
    contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay

  setCurrentViewNumber:(type)->
    KD.whoami().count? type, (err, count)=>
      @getView().$(".activityhead span.member-numbers-#{type}").html count

  setCurrentViewHeader:(count)->
    if typeof 1 isnt typeof count
      @getView().$(".activityhead span.optional_title").html count
      return no

    if count >= 10 then count = '10+'
    # return if count % 10 is 0 and count isnt 20
    # postfix = if count is 10 then '+' else ''
    count   = 'No' if count is 0
    result  = "#{count} member" + if count isnt 1 then 's' else ''
    title   = "#{result} found for <strong>#{@_searchValue}</strong>"
    @getView().$(".activityhead span.optional_title").html title

  fetchFeedForHomePage:(callback)->
    options  =
      limit  : 6
      skip   : 0
      sort   : "meta.modifiedAt" : -1
    selector = {}
    KD.remote.api.JAccount.someWithRelationship selector, options, callback

  fetchSomeMembers:(options = {}, callback)->

    options.limit or= 6
    options.skip  or= 0
    options.sort  or= "meta.modifiedAt" : -1
    selector        = options.selector or {}

    delete options.selector if options.selector

    KD.remote.api.JAccount.byRelevance selector, options, callback


class MembersListViewController extends KDListViewController
  _windowDidResize:()->
    @scrollView.setHeight @getView().getHeight() - 28

  loadView:(mainView)->
    super

    @getListView().on 'ItemWasAdded', (view)=> @addListenersForItem view

  addItem:(member, index, animation = null) ->
    @getListView().addItem member, index, animation

  addListenersForItem:(item)->
    data = item.getData()

    data.on 'FollowCountChanged', (followCounts)=>
      {followerCount, followingCount, newFollower, oldFollower} = followCounts
      data.counts.followers = followerCount
      data.counts.following = followingCount
      item.setFollowerCount followerCount
      switch @getSingleton('mainController').getVisitor().currentDelegate
        when newFollower, oldFollower
          if newFollower then item.unfollowTheButton() else item.followTheButton()

    item.registerListener KDEventTypes : "FollowButtonClicked",   listener : @, callback : @followAccount
    item.registerListener KDEventTypes : "UnfollowButtonClicked", listener : @, callback : @unfollowAccount
    item.registerListener KDEventTypes : "MemberWantsToBeShown",  listener : @, callback : @getDelegate().showMemberContentDisplay
    @

  followAccount:(pubInst, {account,callback})->
    account.follow callback

  unfollowAccount:(pubInst, {account,callback})->
    account.unfollow callback

  reloadView:()->
    {query, skip, limit, currentFilter} = @getOptions()
    controller = @

    currentFilter query, {skip, limit}, (err, members)->
      controller.removeAllItems()
      controller.propagateEvent (KDEventType : 'DisplayedMembersCountChanged'), members.length
      controller.instantiateListItems members
      if (myItem = controller.itemForId KD.whoami().getId())?
        myItem.isMyItem()
        myItem.registerListener KDEventTypes : "VisitorProfileWantsToBeShown", listener : controller, callback : controller.getDelegate().showMemberContentDisplay
      controller._windowDidResize()

  pageDown:()->
    listController = @
    {query, skip, limit, currentFilter} = @getOptions()
    skip += @getItemCount()
    unless listController.isLoading
      listController.isLoading = yes
      currentFilter query, {skip, limit}, (err, members)->
        listController.addItem member for member in members
        if (myItem = listController.itemForId KD.whoami().getId())?
          myItem.isMyItem()
          myItem.registerListener KDEventTypes : "VisitorProfileWantsToBeShown", listener : listController, callback : listController.getDelegate().showMemberContentDisplay
        listController._windowDidResize()
        listController.propagateEvent (KDEventType : 'DisplayedMembersCountChanged'), skip + members.length
        listController.isLoading = no
        listController.hideLazyLoader()

  getTotalMemberCount:(callback)=>
    KD.whoami().count? @getOptions().filterName, callback
