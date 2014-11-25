class ActivityListController extends KDListViewController

  {dash} = Bongo

  constructor:(options={}, data)->

    options.startWithLazyLoader  ?= yes
    options.lazyLoaderOptions    ?=
      spinnerOptions              : size : width : 24
      partial                     : ''
    options.showHeader           ?= yes
    options.scrollView           ?= yes
    options.wrapper              ?= no
    options.boxed                ?= yes
    options.itemClass           or= ActivityListItemView

    options.viewOptions         or= {}
    {viewOptions}                 = options
    viewOptions.cssClass          = KD.utils.curry 'activity-related', viewOptions.cssClass
    viewOptions.type              = options.type
    viewOptions.comments         ?= yes
    viewOptions.dataPath          = 'id'
    viewOptions.attributes        =
      testpath                    : 'activity-list'

    options.noItemFoundWidget    ?= new KDCustomHTMLView
      cssClass : 'no-item-found hidden'
      partial  : 'There is no activity.'

    options.lazyLoaderOptions =
      spinnerOptions  :
        size          : width: 14, height: 14
        loaderOptions :
          shape       : 'spiral'
          color       : '#9d9d9d'

    super options, data

    @hiddenItems = []


  getIndex: (index) ->
    return if @getOptions().lastToFirst
    then index
    else @getItemCount() - index - 1


  # LEGACY

  postIsCreated: (post) =>
    bugTag   = tag for tag in post.subject.tags when tag.slug is 'bug'
    subject  = @prepareSubject post
    instance = @addItem subject, 0

    return  unless instance

    if bugTag and not @isMine subject
      instance.hide()
      @hiddenItems.push instance

    liveUpdate = @activityHeader?.liveUpdateToggle.getState().title is 'live'
    if not liveUpdate and not @isMine subject
      instance.hide()
      @hiddenItems.push instance
      @activityHeader.newActivityArrived() unless bugTag

  prepareSubject:(post)->
    {subject} = post
    subject = KD.remote.revive subject
    @bindItemEvents subject
    return subject

  isMine:(activity)->
    id = KD.whoami().getId()
    id? and id in [activity.account._id, activity.anchor?.id]

  unhideNewHiddenItems: ->

    @hiddenItems.forEach (item)-> item.show()

    @hiddenItems = []

    unless KD.getSingleton("router").getCurrentPath() is "/Activity"
      KD.getSingleton("activityController").clearNewItemsCount()
