class ActivityListController extends KDListViewController

  hiddenItems               = []
  hiddenNewMemberItemGroups = [[]]
  hiddenItemCount           = 0

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
    u  = @utils
    gr = u.getRandomNumber
    gp = u.generatePassword

    unless KD.isLoggedIn()
      @utils.wait 5000, =>
        # bucket = new KD.remote.api.CNewMemberBucket
        #   anchor     : KD.whoami()
        #   sourceName : 'JAccount'

        # @utils.repeat 2500, =>
          # @newActivityArrived bucket

        uniqueness = (Date.now()+"").slice(6)
        formData   =
          agree           : "on"
          email           : "#{uniqueness}@sinanyasar.com"
          firstName       : gp(gr(10), yes)
          inviteCode      : "twitterfriends"
          lastName        : gp(gr(10), yes)
          password        : "123123123"
          passwordConfirm : "123123123"
          username        : uniqueness

        @utils.wait 5000, =>
          KD.remote.api.JUser.register formData, (error, account, replacementToken)=>
            location.reload yes
    # else

      # @utils.repeat 90000, =>
      #   status = dateFormat(Date.now(), "dddd, mmmm dS, yyyy, h:MM:ss TT");
      #   KD.remote.api.JStatusUpdate.create body : status, (err,reply)=>
      #     unless err
      #       appManager.tell 'Activity', 'ownActivityArrived', reply
      #     else
      #       new KDNotificationView type : "mini", title : "There was an error, try again later!"

    # @utils.repeat 10000, =>



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

  teasersLoaded:->

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

    hiddenNewMemberItemGroups = [[]]


  isMine:(activity)->
    id = KD.whoami().getId()
    id? and id in [activity.originId, activity.anchor?.id]

  followedActivityArrived: (activity) ->

    if @_state is 'private'
      view = @addHiddenItem activity, 0
      @activityHeader.newActivityArrived()

  newActivityArrived:(activity)->

    return unless @_state is 'public'
    unless @isMine activity
      if activity instanceof KD.remote.api.CNewMemberBucketActivity
        activity.snapshot = activity.snapshot?.replace /&quot;/g, '"'
        KD.remote.reviveFromSnapshots [activity], (err, [bucket])=>
          for item in @itemsOrdered
            if item.getData() instanceof NewMemberBucketData
              data = item.getData()
              data.buckets.unshift bucket
              item.destroySubViews()
              item.addChildView data
              break
      else
        view = @addHiddenItem activity, 0
        @activityHeader.newActivityArrived()
    else
      {CFolloweeBucket} = KD.remote.api
      switch activity.constructor
        when CFolloweeBucket
          @addItem activity, 0
      @ownActivityArrived activity

  ownActivityArrived:(activity)->

    view = @getListView().addHiddenItem activity, 0
    view.addChildView activity, ()=>
      @scrollView.scrollTo {top : 0, duration : 200}, ->
        view.slideIn()

  addHiddenItem:(activity, index, animation = null)->

    # log "addHiddenItem"

    instance = @getListView().addHiddenItem activity, index, animation

    if activity instanceof KD.remote.api.CNewMemberBucket
      hiddenNewMemberItemGroups[hiddenNewMemberItemGroups.length-1].push instance
    else
      hiddenItems.push instance
      if hiddenNewMemberItemGroups[hiddenNewMemberItemGroups.length-1].length isnt 0
        hiddenNewMemberItemGroups.push []

    return instance

  addItem:(activity, index, animation = null) ->

    # log "addItem"
    # return if activity instanceof KD.remote.api.CNewMemberBucket

    @noActivityItem.hide()
    if activity instanceof KD.remote.api.CNewMemberBucket
      @addHiddenItem activity, index, animation
    else
      @getListView().addItem activity, index, animation
      if hiddenNewMemberItemGroups[hiddenNewMemberItemGroups.length-1].length isnt 0
        hiddenNewMemberItemGroups.push []

  unhideNewHiddenItems = (hiddenItems)->

    repeater = KD.utils.repeat 177, ->
      item = hiddenItems.shift()
      if item then item.show() else KD.utils.killRepeat repeater
