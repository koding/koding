class ActivityListController extends KDListViewController

  {dash} = Bongo

  constructor:(options={}, data)->

    viewOptions = options.viewOptions or {}
    viewOptions.cssClass      or= 'activity-related'
    viewOptions.comments       ?= yes
    viewOptions.itemClass     or= options.itemClass
    options.view              or= new KDListView viewOptions, data
    options.startWithLazyLoader = yes
    options.showHeader         ?= no
    options.noItemFoundWidget or= new KDCustomHTMLView
      cssClass : "lazy-loader hidden"
      partial  : "There is no activity."

    # this is regressed until i touch this again. - SY
    # options.noMoreItemFoundWidget or= new KDCustomHTMLView
    #   cssClass : "lazy-loader"
    #   partial  : "There is no more activity."

    super options, data

    @resetList()
    @hiddenItems = []
    @_state      = 'public'

    KD.getSingleton("groupsController").on "MemberJoinedGroup", (member) =>
      @updateNewMemberBucket member.member

    KD.getSingleton("groupsController").on "FollowHappened", (info) =>
      {follower, origin} = info
      @updateFollowerBucket follower, origin

  resetList:->
    @newActivityArrivedList = {}
    @lastItemTimeStamp = null

  loadView:(mainView)->

    data = @getData()
    mainView.addSubView @activityHeader = new ActivityListHeader
      cssClass : 'feeder-header clearfix'

    @activityHeader.hide()  unless @getOptions().showHeader

    @activityHeader.on "UnhideHiddenNewItems", =>
      firstHiddenItem = @getListView().$('.hidden-item').eq(0)
      if firstHiddenItem.length > 0
        top   = firstHiddenItem.position().top
        top or= 0
        @scrollView.scrollTo {top, duration : 200}, =>
          @unhideNewHiddenItems @hiddenItems

    @emit "ready"
    KD.getSingleton("activityController").clearNewItemsCount()

    super

  isMine:(activity)->
    id = KD.whoami().getId()
    id? and id in [activity.originId, activity.anchor?.id]

  listActivities:(activities)->
    @hideLazyLoader()
    return  unless activities.length > 0
    activityIds = []
    queue = []

    activities.forEach (activity)=>
      queue.push =>
        @addItem activity
        activityIds.push activity._id
        queue.fin()

    dash queue, =>

      @checkIfLikedBefore activityIds

      @lastItemTimeStamp or= Date.now()

      for obj in activities
        objectTimestamp = (new Date(obj.meta.createdAt)).getTime()
        if objectTimestamp < @lastItemTimeStamp
          @lastItemTimeStamp = objectTimestamp

      @emit "teasersLoaded"

  checkIfLikedBefore:(activityIds)->
    KD.remote.api.CActivity.checkIfLikedBefore activityIds, (err, likedIds)=>
      for activity in @getListView().items when activity.data.getId().toString() in likedIds
        likeView = activity.subViews.first.actionLinks?.likeView
        if likeView
          likeView.setClass "liked"
          likeView._currentState = yes

  logNewActivityArrived:(activity)->
    id = activity.getId?()
    return unless id

    if @newActivityArrivedList[id]
      log "duplicate new activity", activity
    else
      @newActivityArrivedList[id] = true

  newActivityArrived:(activity)->

    @logNewActivityArrived(activity)

    return unless @_state is 'public'
    unless @isMine activity
      # if realtime update is newmember item
      # instead of adding a new item we update the
      # latest inserted member bucket or create a new one
      if activity instanceof KD.remote.api.CNewMemberBucketActivity
        @updateNewMemberBucket activity
      else
        view = @addHiddenItem activity, 0
        @activityHeader?.newActivityArrived()

  updateNewMemberBucket:(memberAccount)->
    for item in @itemsOrdered
      if item.getData() instanceof NewMemberBucketData
        @updateBucket item, "JAccount", memberAccount.id
        break

  updateFollowerBucket:(follower, followee)->
    for item in @itemsOrdered
      data = item.getData()

      continue  if typeof data.group is "string"
      continue  unless data.group
      continue  unless data.group[0]

      if data.group[0].constructorName is followee.bongo_.constructorName
        if data.anchor && data.anchor.id is follower.id
          @updateBucket item, followee.bongo_.constructorName, followee._id
          break

  updateBucket:(item, constructorName, id)->
    data = item.getData()
    group = data.group or data.anchors
    group.unshift {
      bongo_:
        constructorName:"ObjectRef"
      constructorName
      id
    }
    data.createdAtTimestamps.push (new Date).toJSON()
    data.count ||= 0
    data.count++
    item.slideOut =>
      @removeItem item, data
      newItem = @addHiddenItem data, 0
      @utils.wait 500, -> newItem.slideIn()

  fakeItems = []

  addItem:(activity, index, animation) ->
    dataId = activity.getId?() or activity._id
    if dataId?
      if @itemsIndexed[dataId]
        log "duplicate entry", activity.bongo_?.constructorName, dataId
      else
        @itemsIndexed[dataId] = activity
        super(activity, index, animation)

  ownActivityArrived:(activity)->

    @lastItemTimeStamp = activity.createdAt or activity.meta.createdAt
    if fakeItems.length > 0
      itemToBeRemoved = fakeItems.shift()
      @removeItem null, itemToBeRemoved
      @getListView().addItem activity, 0
    else
      view = @addHiddenItem activity, 0
      @utils.defer =>
        view.slideIn => @removeFromHiddenItems view

  removeFromHiddenItems: (view)->
    @hiddenItems.splice @hiddenItems.indexOf(view), 1


  fakeActivityArrived:(activity)->

    @ownActivityArrived activity
    fakeItems.push activity

  addHiddenItem:(activity, index, animation = null)->

    instance = @getListView().addHiddenItem activity, index, animation
    @hiddenItems.push instance
    @lastItemTimeStamp = activity.createdAt

    return instance

  unhideNewHiddenItems: ->

    repeater = KD.utils.repeat 177, =>
      item = @hiddenItems.shift()
      if item then item.show() else
        KD.utils.killRepeat repeater
        unless KD.getSingleton("router").getCurrentPath() is "/Activity"
          KD.getSingleton("activityController").clearNewItemsCount()

  instantiateListItems:(items)->
    newItems = super
    @checkIfLikedBefore (item.getId()  for item in items)
    return newItems