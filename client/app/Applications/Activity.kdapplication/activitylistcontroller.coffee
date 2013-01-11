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

    @noActivityItem.hide()

  loadView:(mainView)->

    @noActivityItem.hide()


    data = @getData()
    mainView.addSubView @activityHeader = new ActivityListHeader
      cssClass : 'activityhead clearfix'

    @scrollView.on 'scroll', (event) =>
      if event.delegateTarget.scrollTop > 10
        @activityHeader.setClass "scrolling-up-outset"
      else
        @activityHeader.unsetClass "scrolling-up-outset"

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

    for activity in activities
      @addItem activity

    @teasersLoaded()

  listActivitiesFromCache:(cache)->

    for item in cache.overview
      if item.ids.length > 1
        @addItem new NewMemberBucketData
          type      : "CNewMemberBucketActivity"
          anchors   : (cache.activities[id].teaser.anchor for id in item.ids)
          count     : item.count
          createdAt : item.createdAt
      else
        if cache.activities[item.ids.first]
          @addItem cache.activities[item.ids.first].teaser

    @teasersLoaded()

  teasersLoaded:->
    @emit "teasersLoaded"

    return
    for group in hiddenNewMemberItemGroups

      if group.length > 0
        activity = new NewMemberBucketData {}, group.map (view)-> view.getData()
        for item, i in @itemsOrdered
          a = new Date(activity.buckets[0].meta.createdAt).getTime()
          b = new Date(item.getData().meta.createdAt).getTime()
          if a > b
            @addItem activity, i
            break

      item.destroy() for item in group

    resetNewMemberGroups()


















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
    # else
    #   # i don't know what this does
    #   {CFolloweeBucket} = KD.remote.api
    #   switch activity.constructor
    #     when CFolloweeBucket
    #       @addItem activity, 0
    #   @ownActivityArrived activity

  updateNewMemberBucket:(activity)->

    return unless activity.snapshot?

    activity.snapshot = activity.snapshot.replace /&quot;/g, '"'
    KD.remote.reviveFromSnapshots [activity], (err, [bucket])=>
      for item in @itemsOrdered
        if item.getData() instanceof NewMemberBucketData
          data = item.getData()
          data.buckets.unshift bucket
          item.destroySubViews()
          item.addChildView data
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

    # if the item is a new member bucket
    # (don't let the name mislead you it is not a bucket, contains only one member)
    # we make a separate group of new member groups
    if activity instanceof KD.remote.api.CNewMemberBucket
      hiddenNewMemberItemGroups[hiddenNewMemberItemGroups.length-1].push instance
    else
      hiddenItems.push instance
      prepareNewMemberGroup()

    return instance

  # addItem:(activity, index, animation = null) ->

  #   @noActivityItem.hide()
  #   if activity instanceof KD.remote.api.CNewMemberBucket
  #     @addHiddenItem activity, index, animation
  #   else
  #     @getListView().addItem activity, index, animation
  #     prepareNewMemberGroup()

  unhideNewHiddenItems = (hiddenItems)->

    repeater = KD.utils.repeat 177, ->
      item = hiddenItems.shift()
      if item then item.show() else KD.utils.killRepeat repeater
