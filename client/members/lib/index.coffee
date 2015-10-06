kd = require 'kd'
KDListViewController = kd.ListViewController
KDView = kd.View
MemberActivityListController = require './memberactivitylistcontroller'
ContentDisplayScrollableView = require './contentdisplays/contentdisplayscrollableview'
GroupMembersPageListItemView = require './groupmemberspagelistitemview'
ProfileView = require './contentdisplays/profileview'
remote = require('app/remote').getInstance()
globals = require 'globals'
getFullnameFromAccount = require 'app/util/getFullnameFromAccount'
getGroup = require 'app/util/getGroup'
whoami = require 'app/util/whoami'
isMine = require 'app/util/isMine'
AppController = require 'app/appcontroller'
ActivityListItemView = require 'activity/views/activitylistitemview'
FilterLinksView = require 'activity/views/filterlinksview'


module.exports = class MembersAppController extends AppController

  @options =
    name         : 'Members'
    dependencies : [ 'Activity' ]

  {externalProfiles} = globals.config

  constructor:(options = {}, data)->
    options.view    = new KDView
      cssClass      : 'content-page members'
    options.appInfo =
      name          : 'Members'

    @appManager = kd.getSingleton "appManager"

    super options, data

  createContentDisplay:(model, callback=->)->
    kd.singletons.appManager.setFrontApp this
    {JAccount} = remote.api
    type = if model instanceof JAccount then "profile" else "members"

    contentDisplay = new KDView
      cssClass : 'member content-display'
      type     : type

    contentDisplay.on 'handleQuery', (query)=>
      @ready => @feedController?.handleQuery? query

    contentDisplay.once 'KDObjectWillBeDestroyed', ->
      kd.singleton('appManager').tell 'Activity', 'resetProfileLastTo'

    kd.getSingleton('groupsController').ready =>
      contentDisplay.$('div.lazy').remove()
      if type is "profile"
        @createProfileView contentDisplay, model
      else
        @createGroupMembersView contentDisplay

      contentDisplay.addSubView new FilterLinksView
        filters    : ['Posts']
        default    : 'Posts'

      @showContentDisplay contentDisplay
      kd.utils.defer -> callback contentDisplay

  createProfileView: (contentDisplay, model)->
    @prepareProfileView model, (profileView)=>
      contentDisplay.addSubView profileView
      @prepareFeederView model, (feederView)->
        contentDisplay.addSubView feederView

  createGroupMembersView: (contentDisplay)->
    # assuming, not being used - sy

    # contentDisplay.addSubView new HeaderViewSection
    #   title    : "Members"
    #   type     : "big"
    @prepareFeederView whoami(), (feederView)->
      contentDisplay.addSubView feederView

  prepareFeederView:(account, callback)->
    windowController = kd.getSingleton('windowController')

    if isMine account
      owner   = "you"
      auxVerb =
        have : "have"
        be   : "are"
    else
      owner = getFullnameFromAccount account
      auxVerb =
        have : "has"
        be   : "is"

    kd.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', {
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
            kd.singletons.socialapi.channel.fetchProfileFeed options, callback
        followers           :
          loggedInOnly      : yes
          itemClass         : GroupMembersPageListItemView
          listControllerClass: KDListViewController
          listCssClass      : "member-related"
          noItemFoundText   : "No one is following #{owner} yet."
          dataSource        : (selector, options, callback)=>
            options.groupId or= getGroup().getId()
            account.fetchFollowersWithRelationship selector, options, callback
        following           :
          loggedInOnly      : yes
          itemClass         : GroupMembersPageListItemView
          listControllerClass: KDListViewController
          listCssClass      : "member-related"
          noItemFoundText   : "#{owner} #{auxVerb.be} not following anyone."
          dataSource        : (selector, options, callback)=>
            options.groupId or= getGroup().getId()
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
            group = getGroup()
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

    if isMine member
      options.cssClass = kd.utils.curry "own-profile", options.cssClass
    else
      options.bind = "mouseenter" unless isMine member

    callback new ProfileView options, member

  showContentDisplay:(contentDisplay)->

    view = new ContentDisplayScrollableView
      contentDisplay : contentDisplay

    @forwardEvent view, 'LazyLoadThresholdReached'

    kd.singleton('display').emit "ContentDisplayWantsToBeShown", view
    return contentDisplay

  fetchFeedForHomePage:(callback)->
    options  =
      limit  : 6
      skip   : 0
      sort   : "meta.modifiedAt" : -1
    selector = {}
    remote.api.JAccount.someWithRelationship selector, options, callback

  fetchSomeMembers:(options = {}, callback)->

    options.limit or= 6
    options.skip  or= 0
    options.sort  or= "meta.modifiedAt" : -1
    selector        = options.selector or {}

    console.log {selector}

    delete options.selector if options.selector

    remote.api.JAccount.byRelevance selector, options, callback


  fetchExternalProfiles:(account, callback)->

    whitelist = Object.keys(externalProfiles).slice().map (a)-> "ext|profile|#{a}"
    account.fetchStorages  whitelist, callback
