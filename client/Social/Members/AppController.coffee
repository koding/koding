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

    @once "MemberListLoaded", ->
      KD.mixpanel "Load member list, success"

  createContentDisplay:(model, callback=->)->
    KD.singletons.appManager.setFrontApp this
    {JAccount} = KD.remote.api
    type = if model instanceof JAccount then "profile" else "members"

    contentDisplay = new KDView
      cssClass : 'member content-display'
      type     : type

    contentDisplay.on 'handleQuery', (query)=>
      @ready => @feedController?.handleQuery? query

    contentDisplay.once 'KDObjectWillBeDestroyed', ->
      KD.singleton('appManager').tell 'Activity', 'resetProfileLastTo'

    KD.getSingleton('groupsController').ready =>
      contentDisplay.$('div.lazy').remove()
      if type is "profile"
        @createProfileView contentDisplay, model
      else
        @createGroupMembersView contentDisplay

      contentDisplay.addSubView new MemberTabsView {}, model

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
            options.targetId = account.socialApiId
            KD.singletons.socialapi.channel.fetchProfileFeed options, callback
        followers           :
          loggedInOnly      : yes
          itemClass         : GroupMembersPageListItemView
          listControllerClass: KDListViewController
          listCssClass      : "member-related"
          noItemFoundText   : "No one is following #{owner} yet."
          dataSource        : (selector, options, callback)=>
            options.groupId or= KD.getGroup().getId()
            account.fetchFollowersWithRelationship selector, options, callback
        following           :
          loggedInOnly      : yes
          itemClass         : GroupMembersPageListItemView
          listControllerClass: KDListViewController
          listCssClass      : "member-related"
          noItemFoundText   : "#{owner} #{auxVerb.be} not following anyone."
          dataSource        : (selector, options, callback)=>
            options.groupId or= KD.getGroup().getId()
            account.fetchFollowingWithRelationship selector, options, callback
        likes               :
          loggedInOnly      : yes
          noItemFoundText   : "#{owner} #{auxVerb.have} not liked any posts yet."
          dataSource        : (selector, options, callback)->
            return callback {message: "not impplemented feature"}
        members              :
          noItemFoundText    : "There is no member."
          itemClass          : GroupMembersPageListItemView
          listControllerClass: KDListViewController
          listCssClass       : "member-related"
          title              : ""
          dataSource         : (selector, options, callback)=>
            group = KD.getGroup()
            group.fetchMembers selector, options, (err, res)=>
              @emit "MemberListLoaded"  unless err
              callback err, res

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
      tagName    : 'aside'
      cssClass   : "app-sidebar clearfix"

    if KD.isMine member
      options.cssClass = KD.utils.curry "own-profile", options.cssClass
    else
      options.bind = "mouseenter" unless KD.isMine member

    callback new ProfileView options, member

  showContentDisplay:(contentDisplay)->

    KD.singleton('display').emit "ContentDisplayWantsToBeShown", contentDisplay
    return contentDisplay

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

class MemberTabsView extends KDCustomHTMLView
  constructor: (options = {}, data) ->
    options.cssClass    = 'member-tabs'
    options.tagName     = 'nav'
    super options, data

    @addSubView new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'active'
      partial    : "Posts"

class MemberActivityListController extends ActivityListController
  # used for filtering received live updates
  addItem: (activity, index, animation)->
    if activity.account._id is @getOptions().creator.getId()
      super activity, index, animation
