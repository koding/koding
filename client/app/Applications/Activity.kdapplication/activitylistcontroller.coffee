class ActivityListController extends KDListViewController

  hiddenItems               = []
  hiddenNewMemberItemGroups = [[]]
  hiddenItemCount           = 0

  prepareNewMemberGroup = ->

    # this is a bit tricky here
    # if the previous member group isn't empty
    # create a new group for later new member items
    if hiddenNewMemberItemGroups.last.length isnt 0
      hiddenNewMemberItemGroups.push []

  resetNewMemberGroups = -> hiddenNewMemberItemGroups = [[]]

  constructor:(options,data)->

    viewOptions = options.viewOptions or {}
    viewOptions.cssClass      or= 'activity-related'
    viewOptions.comments      or= yes
    viewOptions.itemClass     or= options.itemClass
    options.view              or= new KDListView viewOptions, data
    options.startWithLazyLoader = yes

    super

    @resetList()

    @_state = 'public'

    @scrollView.addSubView @noActivityItem = new KDCustomHTMLView
      cssClass : "lazy-loader"
      partial  : "There is no activity item."

    @scrollView.on 'scroll', (event) =>
      if event.delegateTarget.scrollTop > 0
        @activityHeader.setClass "scrolling-up-outset"
        @activityHeader.liveUpdateButton.setValue off
      else
        @emit "scrolledToTopOfPage"

        @activityHeader.unsetClass "scrolling-up-outset"
        @activityHeader.liveUpdateButton.setValue on

    @noActivityItem.hide()

  resetList:->
    @newActivityArrivedList = {}
    @lastItemTimeStamp = null

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

  isMine:(activity)->
    id = KD.whoami().getId()
    id? and id in [activity.originId, activity.anchor?.id]

  listActivities:(activities)->

    for activity in activities when activity
      @addItem activity

    modifiedAt = _.compact(activities).first.meta.createdAt
    unless @lastItemTimeStamp > modifiedAt
      # HACK: activity timestamp is off -200 ms on first get
      time = new Date(modifiedAt).getTime()+1000
      @lastItemTimeStamp = new Date(time).toISOString()

    @emit "teasersLoaded"

  listActivitiesFromCache:(cache)->

    return @noActivityItem.show() unless Object.keys(cache).length

    for overviewItem in cache.overview when overviewItem
      if overviewItem.ids.length > 1 and overviewItem.type is "CNewMemberBucketActivity"
        @addItem new NewMemberBucketData
          type                : "CNewMemberBucketActivity"
          anchors             : (cache.activities[id].teaser.anchor for id in overviewItem.ids)
          count               : overviewItem.count
          createdAtTimestamps : overviewItem.createdAt
      else
        activity = cache.activities[overviewItem.ids.first]
        if activity?.teaser
          activity.teaser.createdAtTimestamps = overviewItem.createdAt
          @addItem activity.teaser

    sortedActivities = _.sortBy cache.activities, (activity) ->
      activity.modifiedAt

    modifiedAt = sortedActivities.last.modifiedAt
    @lastItemTimeStamp = modifiedAt  unless @lastItemTimeStamp > modifiedAt

    @emit "teasersLoaded"

  getLastItemTimeStamp: ->

    if item = hiddenItems.first
      item.getData().createdAt or item.getData().createdAtTimestamps.last
    else
      @lastItemTimeStamp

  followedActivityArrived: (activity) ->

    if @_state is 'private'
      view = @addHiddenItem activity, 0
      @activityHeader?.newActivityArrived()

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

  updateNewMemberBucket:(activity)->

    return unless activity.snapshot?

    activityCreatedAt = activity.createdAt or (new Date()).toString()
    activity.snapshot = activity.snapshot.replace /&quot;/g, '"'
    KD.remote.reviveFromSnapshots [activity], (err, [bucket])=>
      for item in @itemsOrdered
        if item.getData() instanceof NewMemberBucketData
          data = item.getData()
          if data.count > 3
            data.anchors.pop()
          data.anchors.unshift bucket.anchor
          data.createdAtTimestamps.push activityCreatedAt
          data.count++
          item.slideOut =>
            @removeItem item, data
            newItem = @addHiddenItem data, 0
            @utils.wait 500, -> newItem.slideIn()
          break


  fakeItems = []

  addItem:(activity, index, animation) ->
    dataId = activity.getId?()

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
      @utils.defer ->
        view.slideIn ->
          hiddenItems.splice hiddenItems.indexOf(view), 1

  fakeActivityArrived:(activity)->

    @ownActivityArrived activity
    fakeItems.push activity

  addHiddenItem:(activity, index, animation = null)->

    instance = @getListView().addHiddenItem activity, index, animation
    hiddenItems.push instance
    @lastItemTimeStamp = activity.createdAt

    return instance

  unhideNewHiddenItems = (hiddenItems)->

    repeater = KD.utils.repeat 177, ->
      item = hiddenItems.shift()
      if item then item.show() else KD.utils.killRepeat repeater
