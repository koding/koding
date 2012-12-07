class ActivityListController extends KDListViewController

  hiddenItems     = []
  hiddenItemCount = 0

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
      partial  : "There is no activity from your followings."

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

  ownActivityArrived:(activity)->

    view = @getListView().addHiddenItem activity, 0
    view.addChildView activity, ()=>
      @scrollView.scrollTo {top : 0, duration : 200}, ->
        view.slideIn()

  followedActivityArrived: (activity) ->

    if @_state is 'private'
      view = @addHiddenItem activity, 0
      @activityHeader.newActivityArrived()

  isMine:(activity)->
    id = KD.whoami().getId()
    id? and id in [activity.originId, activity.anchor?.id]

  newActivityArrived:(activity)->

    return unless @_state is 'public'

    unless @isMine activity
      view = @addHiddenItem activity, 0
      @activityHeader.newActivityArrived()

    else
      switch activity.constructor
        when KD.remote.api.CFolloweeBucket
          @addItem activity, 0
      @ownActivityArrived activity

  addHiddenItem:(activity, index, animation = null)->

    instance = @getListView().addHiddenItem activity, index, animation
    hiddenItems.push instance
    return instance

  addItem:(activity, index, animation = null) ->

    # log activity
    # return if activity instanceof KD.remote.api.CNewMemberBucket

    @noActivityItem.hide()
    @getListView().addItem activity, index, animation

  unhideNewHiddenItems = (hiddenItems)->

    interval = setInterval ->
      item = hiddenItems.shift()
      if item
        item.show()
      else
        clearInterval interval
    , 177
