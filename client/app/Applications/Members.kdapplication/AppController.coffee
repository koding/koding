class MembersAppController extends AppController

  KD.registerAppClass this,
    name         : "Members"
    route        : "/:name?/Members"
    hiddenHandle : yes
    navItem      :
      title      : "Members"
      path       : "/Members"
      order      : 30

  constructor:(options = {}, data)->

    options.view    = new MembersMainView
      cssClass      : 'content-page members'
    options.appInfo =
      name          : 'Members'

    @appManager = KD.getSingleton "appManager"

    super options, data

  createFeed:(view, loadFeed = no)->
    @appManager.tell 'Feeder', 'createContentFeedController', {
      itemClass             : MembersListItemView
      listControllerClass   : MembersListViewController
      useHeaderNav          : no
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
            {JAccount} = KD.remote.api
            if @_searchValue
              @setCurrentViewHeader "Searching for <strong>#{@_searchValue}</strong>..."
              JAccount.byRelevance @_searchValue, options, callback
            else
              group = KD.getSingleton('groupsController').getCurrentGroup()
              group.fetchMembersFromGraph options, callback
              JAccount.count selector, (err, count)=>
                @setCurrentViewNumber 'all', count

        followed            :
          loggedInOnly      : yes
          title             : "Followers <span class='member-numbers-followers'></span>"
          noItemFoundText   : "There is no member who follows you."
          dataSource        : (selector, options, callback)=>
            options.groupId or= KD.getSingleton('groupsController').getCurrentGroup().getId()
            KD.whoami().fetchMyFollowersFromGraph options, callback

            KD.whoami().countFollowersWithRelationship selector, (err, count)=>
              @setCurrentViewNumber 'followers', count
        followings          :
          loggedInOnly      : yes
          title             : "Following <span class='member-numbers-following'></span>"
          noItemFoundText   : "You are not following anyone."
          dataSource        : (selector, options, callback)=>
            options.groupId or= KD.getSingleton('groupsController').getCurrentGroup().getId()
            KD.whoami().fetchMyFollowingsFromGraph options, callback

            KD.whoami().countFollowingWithRelationship selector, (err, count)=>
              @setCurrentViewNumber 'following', count
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
      @feedController.loadFeed() if loadFeed
      view.addSubView @_lastSubview = controller.getView()
      @emit 'ready'
      controller.on "FeederListViewItemCountChanged", (count, filter)=>
        if @_searchValue and filter is 'everything'
          @setCurrentViewHeader count

  createFeedForContentDisplay:(view, account, followersOrFollowing, callback)->

    @appManager.tell 'Feeder', 'createContentFeedController', {
      # domId                 : 'members-feeder-split-view'
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
      contentDisplayController = KD.getSingleton "contentDisplayController"
      contentDisplayController.emit "ContentDisplayWantsToBeShown", view
      callback view, controller
      if controller.facetsController?.filterController?
        controller.emit 'ready'
      else
        controller.getView().on 'viewAppended', -> controller.emit 'ready'

  createFolloweeContentDisplay:(account, filter, callback)->
    # log "I need to create followee for", account, filter
    newView = new MembersContentDisplayView
      cssClass : "content-display #{filter}"
      # domId    : 'members-feeder-split-view'
    newView.createCommons(account, filter)
    @createFeedForContentDisplay newView, account, filter, callback

  createLikedFeedForContentDisplay:(view, account, callback)->

    @appManager.tell 'Feeder', 'createContentFeedController', {
      # domId                 : 'members-feeder-split-view'
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
      contentDisplayController = KD.getSingleton "contentDisplayController"
      contentDisplayController.emit "ContentDisplayWantsToBeShown", view
      callback view, controller

      if controller.facetsController?.filterController?
        controller.emit 'ready'
      else
        controller.getView().on 'viewAppended', -> controller.emit 'ready'

  createLikedContentDisplay:(account, callback)->
    newView = new MembersLikedContentDisplayView
      cssClass : "content-display likes"
      # domId    : 'members-feeder-split-view'

    newView.createCommons account
    @createLikedFeedForContentDisplay newView, account, callback

  loadView:(mainView, firstRun = yes, loadFeed = no)->
    if firstRun
      mainView.on "searchFilterChanged", (value) =>
        return if value is @_searchValue
        @_searchValue = Encoder.XSSEncode value
        @_lastSubview.destroy?()
        @loadView mainView, no, yes
      mainView.createCommons()
    @createFeed mainView, loadFeed

  # showMemberContentDisplay:({content})->
  #   contentDisplayController = KD.getSingleton "contentDisplayController"
  #   controller = new ContentDisplayControllerMember null, content
  #   contentDisplay = controller.getView()
  #   contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay

  createContentDisplay:(account, callback)->
    controller     = new ContentDisplayControllerMember null, account
    contentDisplay = controller.getView()
    contentDisplay.on 'handleQuery', (query)=>
      controller.ready -> controller.feedController?.handleQuery? query
    @showContentDisplay contentDisplay
    @utils.defer -> callback contentDisplay

  createContentDisplayWithOptions:(options, callback)->
    {model, route, query} = options
    kallback = (contentDisplay, controller)=>
      # needed to remove the member display which comes as HTML
      unless KD.getSingleton('router').openRoutes[KD.config.entryPoint?.slug]
        memberDisplay = document.getElementById('member-contentdisplay')
        memberDisplay?.parentNode.removeChild(memberDisplay)

      contentDisplay.on 'handleQuery', (query)->
        controller.ready -> controller.handleQuery? query
      callback contentDisplay

    switch route.split('/')[2]
      when 'Followers'
        @createFolloweeContentDisplay model, 'followers', kallback
      when 'Following'
        @createFolloweeContentDisplay model, 'following', kallback
      when 'Likes'
        @createLikedContentDisplay model, kallback

  showContentDisplay:(contentDisplay)->
    contentDisplayController = KD.getSingleton "contentDisplayController"
    contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay
    return contentDisplay

  setCurrentViewNumber:(type, count)->
    @getView().$(".feeder-header span.member-numbers-#{type}").html count ? "n/a"

  setCurrentViewHeader:(count)->
    if typeof 1 isnt typeof count
      @getView().$(".feeder-header span.optional_title").html count
      return no

    if count >= 10 then count = '10+'
    # return if count % 10 is 0 and count isnt 20
    # postfix = if count is 10 then '+' else ''
    count   = 'No' if count is 0
    result  = "#{count} member" + if count isnt 1 then 's' else ''
    title   = "#{result} found for <strong>#{@_searchValue}</strong>"
    @getView().$(".feeder-header span.optional_title").html title

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

    console.log {selector}

    delete options.selector if options.selector

    KD.remote.api.JAccount.byRelevance selector, options, callback


class MembersListViewController extends KDListViewController
  # _windowDidResize:->
  #   @scrollView.setHeight @getView().getHeight() - 28

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
      switch KD.getSingleton('mainController').getVisitor().currentDelegate
        when newFollower, oldFollower
          if newFollower then item.unfollowTheButton() else item.followTheButton()

    return @

  # reloadView:->
  #   {query, skip, limit, currentFilter} = @getOptions()
  #   controller = @

  #   currentFilter query, {skip, limit}, (err, members)->
  #     controller.removeAllItems()
  #     controller.instantiateListItems members
  #     if (myItem = controller.itemForId KD.whoami().getId())?
  #       myItem.isMyItem()

  #       myItem.on "VisitorProfileWantsToBeShown", controller.getDelegate().bound
  #     controller._windowDidResize()

  # pageDown:->
  #   listController = @
  #   {query, skip, limit, currentFilter} = @getOptions()
  #   skip += @getItemCount()
  #   unless listController.isLoading
  #     listController.isLoading = yes
  #     currentFilter query, {skip, limit}, (err, members)->
  #       listController.addItem member for member in members
  #       if (myItem = listController.itemForId KD.whoami().getId())?
  #         myItem.isMyItem()
  #         myItem.on "VisitorProfileWantsToBeShown", listController.getDelegate().showMemberContentDisplay.bind listController
  #       listController._windowDidResize()
  #       listController.isLoading = no
  #       listController.hideLazyLoader()

  getTotalMemberCount:(callback)->
    KD.whoami().count? @getOptions().filterName, callback
