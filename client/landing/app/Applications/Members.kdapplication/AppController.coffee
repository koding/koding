class Members12345 extends AppController
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

  initAndBringToFront:(options, callback)->
    @bringToFront()
    callback()


  createFeed:(view)->
    appManager.tell 'Feeder', 'createContentFeedController', {
      subItemClass          : MembersListItemView
      listControllerClass   : MembersListViewController
      limitPerPage          : 10
      help                  :
        subtitle            : "Learn About Members"
        tooltip             :
          title             : "<p class=\"bigtwipsy\">These people are all members of koding.com. Learn more about them and their interests, activity and coding prowess here.</p>"
          placement         : "above"
      filter                :
        everything          :
          title             : "All Members <span class='member-numbers-all'></span>"
          dataSource        : (selector, options, callback)=>
            bongo.api.JAccount.someWithRelationship selector, options, callback
            {currentDelegate} = @getSingleton('mainController').getVisitor()
            @setCurrentViewNumber 'all'
        followed            :
          title             : "Followers <span class='member-numbers-followers'></span>"
          dataSource        : (selector, options, callback)=>
            {currentDelegate} = @getSingleton('mainController').getVisitor()
            currentDelegate.fetchFollowersWithRelationship selector, options, callback
            @setCurrentViewNumber 'followers'
        recommended         :
          title             : "Following <span class='member-numbers-following'></span>"
          dataSource        : (selector, options, callback)=>
            {currentDelegate} = @getSingleton('mainController').getVisitor()
            currentDelegate.fetchFollowingWithRelationship selector, options, callback
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

      view.addSubView controller.getView()

  createFeedForContentDisplay:(view, account, followersOrFollowing)->

    appManager.tell 'Feeder', 'createContentFeedController', {
      subItemClass          : MembersListItemView
      listControllerClass   : MembersListViewController
      limitPerPage          : 20
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
      contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeShown", view


  createFollowsContentDisplay:(account, filter)->
    newView = (new MembersContentDisplayView cssClass : "content-display #{filter}")
    newView.createCommons(account, filter)
    @createFeedForContentDisplay newView, account, filter

  loadView:(mainView)->
    mainView.createCommons()
    @createFeed mainView

  showMemberContentDisplay:(pubInst, event)=>
    {content} = event
    contentDisplayController = @getSingleton "contentDisplayController"
    controller = new ContentDisplayControllerMember null, content
    contentDisplay = controller.getView()
    contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeShown",contentDisplay

  showVisitorContentDisplay:(pubInst, event)=>
    {content} = event
    contentDisplayController = @getSingleton "contentDisplayController"
    controller = new ContentDisplayControllerVisitor null, content
    contentDisplay = controller.getView()
    contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeShown",contentDisplay

  createContentDisplay:(account, doShow = yes)->
    if account.equals @getSingleton('mainController').getVisitor().currentDelegate
      controllerClass = ContentDisplayControllerVisitor
    else
      controllerClass = ContentDisplayControllerMember

    controller = new controllerClass null, account
    contentDisplay = controller.getView()
    if doShow
      @showContentDisplay contentDisplay

    return contentDisplay

  showContentDisplay:(contentDisplay)->
    contentDisplayController = @getSingleton "contentDisplayController"
    contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeShown",contentDisplay

  setCurrentViewNumber:(type)->
    {currentDelegate} = @getSingleton('mainController').getVisitor()
    # typeClass =
    currentDelegate.count? type, (err, count)=>
      @getView().$(".activityhead span.member-numbers-#{type}").html count

  fetchFeedForHomePage:(callback)->
    options =
      limit     : 6
      skip      : 0
      sort      :
        "meta.modifiedAt": -1
    selector = {}
    bongo.api.JAccount.someWithRelationship selector, options, callback


class MembersListViewController extends KDListViewController
  _windowDidResize:()->
    @scrollView.setHeight @getView().getHeight() - 28

  loadView:(mainView)->
    log mainView
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
      if (myItem = controller.itemForId controller.getSingleton('mainController').getVisitor().currentDelegate.getId())?
        myItem.isMyItem()
        myItem.registerListener KDEventTypes : "VisitorProfileWantsToBeShown", listener : controller, callback : controller.getDelegate().showVisitorContentDisplay
      controller._windowDidResize()

  pageDown:()->
    listController = @
    {query, skip, limit, currentFilter} = @getOptions()
    skip += @getItemCount()
    unless listController.isLoading
      listController.isLoading = yes
      currentFilter query, {skip, limit}, (err, members)->
        listController.addItem member for member in members
        if (myItem = listController.itemForId listController.getSingleton('mainController').getVisitor().currentDelegate.getId())?
          myItem.isMyItem()
          myItem.registerListener KDEventTypes : "VisitorProfileWantsToBeShown", listener : listController, callback : listController.getDelegate().showVisitorContentDisplay
        listController._windowDidResize()
        listController.propagateEvent (KDEventType : 'DisplayedMembersCountChanged'), skip + members.length
        listController.isLoading = no
        listController.propagateEvent KDEventType : 'LazyLoadComplete'

  getTotalMemberCount:(callback)=>
    {currentDelegate} = @getSingleton('mainController').getVisitor()
    currentDelegate.count? @getOptions().filterName, callback
