class MembersAppController extends AppController

  KD.registerAppClass this,
    name         : "Members"
    routes       :
      "/:name?/Members" : ({params, query}) ->
        {router, appManager} = KD.singletons
        KD.getSingleton('groupsController').ready ->
          group = KD.getGroup()
          KD.getSingleton("appManager").tell 'Members', 'createContentDisplay', group, (contentDisplay) ->
            contentDisplay.emit "handleQuery", {filter: "members"}

    hiddenHandle : yes

  {externalProfiles} = KD.config

  constructor:(options = {}, data)->
    options.view    = new KDView
      cssClass      : 'content-page members'
    options.appInfo =
      name          : 'Members'

    @appManager = KD.getSingleton "appManager"

    super options, data

    @on "LazyLoadThresholdReached", => @feedController?.loadFeed()

  createContentDisplay:(model, callback=->)->
    KD.singletons.appManager.setFrontApp this
    contentDisplay = new KDView
      cssClass : 'member content-display'
      type     : 'profile'

    contentDisplay.on 'handleQuery', (query)=>
      @ready => @feedController?.handleQuery? query

    contentDisplay.once 'KDObjectWillBeDestroyed', ->
      KD.singleton('appManager').tell 'Activity', 'resetProfileLastTo'

    KD.getSingleton('groupsController').ready =>
      contentDisplay.$('div.lazy').remove()
      {JAccount} = KD.remote.api
      if model instanceof JAccount
        @createProfileView contentDisplay, model
      else
        @createGroupMembersView contentDisplay
      @showContentDisplay contentDisplay
      @utils.defer -> callback contentDisplay

  createProfileView: (contentDisplay, model)->
    @prepareProfileView model, (profileView)=>
      contentDisplay.addSubView profileView
      @prepareFeederView model, (feederView)->
        contentDisplay.addSubView feederView
        contentDisplay.setCss minHeight : window.innerHeight

  createGroupMembersView: (contentDisplay)->
    contentDisplay.addSubView new HeaderViewSection
      title    : "Members"
      type     : "big"
    @prepareFeederView KD.whoami(), (feederView)->
      contentDisplay.addSubView feederView
      contentDisplay.setCss minHeight : window.innerHeight

  prepareFeederView:(account, callback)->
    windowController = KD.getSingleton('windowController')

    if KD.isMine account
      owner   = "you"
      auxVerb =
        have : "have"
        be   : "are"
    else
      owner = KD.utils.getFullnameFromAccount account
      auxVerb =
        have : "has"
        be   : "is"

    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', {
      itemClass             : ActivityListItemView
      listControllerClass   : MemberActivityListController
      listCssClass          : "activity-related"
      limitPerPage          : 8
      useHeaderNav          : yes
      delegate              : this
      creator               : account
      filter                :
        statuses            :
          noItemFoundText   : "#{owner} #{auxVerb.have} not shared any posts yet."
          dataSource        : (selector, options = {}, callback)=>
            options.originId = account.getId()
            KD.getSingleton("appManager").tell 'Activity', 'fetchActivitiesProfilePage', options, callback
        followers           :
          loggedInOnly      : yes
          itemClass         : GroupMembersPageListItemView
          listControllerClass: MembersListViewController
          listCssClass      : "member-related"
          noItemFoundText   : "No one is following #{owner} yet."
          dataSource        : (selector, options, callback)=>
            options.groupId or= KD.getGroup().getId()
            account.fetchFollowersWithRelationship selector, options, callback

            account.countFollowersWithRelationship selector, (err, count)=>
              @setCurrentViewNumber 'followers', count
        following           :
          loggedInOnly      : yes
          itemClass         : GroupMembersPageListItemView
          listControllerClass: MembersListViewController
          listCssClass      : "member-related"
          noItemFoundText   : "#{owner} #{auxVerb.be} not following anyone."
          dataSource        : (selector, options, callback)=>
            options.groupId or= KD.getGroup().getId()
            account.fetchFollowingWithRelationship selector, options, callback

            account.countFollowingWithRelationship selector, (err, count)=>
              @setCurrentViewNumber 'following', count
        likes               :
          loggedInOnly      : yes
          noItemFoundText   : "#{owner} #{auxVerb.have} not liked any posts yet."
          dataSource        : (selector, options, callback)->
            selector = {sourceName: $in: ['JNewStatusUpdate']}
            account.fetchLikedContents options, selector, callback
        members              :
          noItemFoundText    : "There is no member."
          itemClass          : GroupMembersPageListItemView
          listControllerClass: MembersListViewController
          listCssClass       : "member-related"
          dataSource         : (selector, options, callback)=>
            group = KD.getGroup()
            group.fetchMembers selector, options, (err, res)=>
              KD.mixpanel "Load member list, success"  unless err
              callback err, res

            group.countMembers (err, count) =>
              count = 0 if err
              @setCurrentViewNumber 'all', count
      sort                  :
        'modifiedAt'        :
          title             : "Latest activity"
          direction         : -1
        'counts.followers'  :
          title             : "Most followers"
          direction         : -1
        'counts.following'  :
          title             : "Most following"
          direction         : -1
        'timestamp|new'     :
          title             : 'Latest activity'
          direction         : -1
        'timestamp|old'     :
          title             : 'Most activity'
          direction         : 1
    }, (controller)=>
      @feedController = controller
      callback controller.getView()
      @emit 'ready'

  prepareProfileView:(member, callback)->
    options      =
      cssClass   : "profilearea clearfix"

    if KD.isMine member
      options.cssClass = KD.utils.curry "own-profile", options.cssClass
    else
      options.bind = "mouseenter" unless KD.isMine member

    callback new ProfileView options, member

  showContentDisplay:(contentDisplay)->

    KD.singleton('display').emit "ContentDisplayWantsToBeShown", contentDisplay
    return contentDisplay

  setCurrentViewNumber:(type, count)->
    countFmt = count.toLocaleString() ? "n/a"
    @getView().$(".feeder-header span.member-numbers-#{type}").text countFmt

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


  fetchExternalProfiles:(account, callback)->

    whitelist = Object.keys(externalProfiles).slice().map (a)-> "ext|profile|#{a}"
    account.fetchStorages  whitelist, callback

class MemberActivityListController extends ActivityListController
  # used for filtering received live updates
  addItem: (activity, index, animation)->
    if activity.originId is @getOptions().creator.getId()
      super activity, index, animation
