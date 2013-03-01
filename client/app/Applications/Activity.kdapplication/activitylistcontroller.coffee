class ActivityListController extends KDListViewController

  hiddenItems               = []
  hiddenNewMemberItemGroups = [[]]
  hiddenItemCount           = 0

  prepareNewMemberGroup = ->

    # this is a bit tricky here
    # if the previous member group isn't empty
    # create a new group for later new member items
    if hiddenNewMemberItemGroups[hiddenNewMemberItemGroups.length-1].length isnt 0
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

    @_state = 'public'

    @scrollView.addSubView @noActivityItem = new KDCustomHTMLView
      cssClass : "lazy-loader"
      partial  : "There is no activity item."

    @scrollView.on 'scroll', (event) =>
      if event.delegateTarget.scrollTop > 0
        @activityHeader.setClass "scrolling-up-outset"
        @activityHeader.liveUpdateButton.setValue off
      else
        @activityHeader.unsetClass "scrolling-up-outset"
        @activityHeader.liveUpdateButton.setValue on

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

  isMine:(activity)->
    id = KD.whoami().getId()
    id? and id in [activity.originId, activity.anchor?.id]

  listActivities:(activities)->

    for activity in activities when activity
      @addItem activity

    @emit "teasersLoaded"

  listActivitiesFromCache:(cache)->

    for overviewItem in cache.overview when overviewItem
      if overviewItem.ids.length > 1
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

    @emit "teasersLoaded"


  followedActivityArrived: (activity) ->

    if @_state is 'private'
      view = @addHiddenItem activity, 0
      @activityHeader.newActivityArrived()

  newActivityArrived:(activity)->

    return unless @_state is 'public'
    unless @isMine activity
      # if realtime update is newmember item
      # instead of adding a new item we update the
      # latest inserted member bucket or create a new one
      if activity instanceof KD.remote.api.CNewMemberBucketActivity
        @updateNewMemberBucket activity
      else
        view = @addHiddenItem activity, 0
        @activityHeader.newActivityArrived()

  updateNewMemberBucket:(activity)->

    return unless activity.snapshot?

    activity.snapshot = activity.snapshot.replace /&quot;/g, '"'
    KD.remote.reviveFromSnapshots [activity], (err, [bucket])=>
      for item in @itemsOrdered
        if item.getData() instanceof NewMemberBucketData
          data = item.getData()
          data.anchors.pop()
          data.anchors.unshift bucket.anchor
          data.count++
          item.slideOut =>
            @removeItem item, data
            newItem = @addHiddenItem data, 0
            @utils.wait 500, -> newItem.slideIn()
          break


  fakeItems = []

  ownActivityArrived:(activity)->

    if fakeItems.length > 0
      itemToBeRemoved = fakeItems.shift()
      @removeItem null, itemToBeRemoved
      @getListView().addItem activity, 0
    else
      view = @addHiddenItem activity, 0
      @utils.defer -> view.slideIn()

  fakeActivityArrived:(activity)->

    @ownActivityArrived activity
    fakeItems.push activity

  addHiddenItem:(activity, index, animation = null)->

    instance = @getListView().addHiddenItem activity, index, animation
    hiddenItems.push instance
    instance

  unhideNewHiddenItems = (hiddenItems)->

    repeater = KD.utils.repeat 177, ->
      item = hiddenItems.shift()
      if item then item.show() else KD.utils.killRepeat repeater
